import Foundation
import Observation

@MainActor @Observable
final class TravelPlannerViewModel {
    private(set) var session: PlannerSession?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var needsNewSession = false
    private(set) var fieldErrors: [String: String] = [:]
    private(set) var items: [PlannerItem] = []
    private(set) var alternatives: [PlannerItem] = []
    var cityId: String?
    var checkIn = PlannerValues.calendar.startOfDay(for: Date())
    var checkOut = PlannerValues.calendar.date(
        byAdding: .day,
        value: 1,
        to: Date()
    )!
    var adults = 1
    var children = 0
    var amount = ""
    var interests: Set<String> = []
    private var optionLabels: [String: String] = [:]
    private var account: String?
    private var locale = "az"
    private var generation = UUID()
    private(set) var isOpeningListing = false
    private(set) var routeError: String?
    private let sessionStorage: PlannerSessionStoring
    private let listingService: ListingLookupServiceProtocol
    private let service: TravelPlannerServiceProtocol
    init(
        service: TravelPlannerServiceProtocol? = nil,
        listingService: ListingLookupServiceProtocol? = nil,
        sessionStorage: PlannerSessionStoring = PlannerSessionStorage()
    ) {
        self.sessionStorage = sessionStorage
        self.listingService = listingService ?? ListingServices()
        self.service = service ?? TravelPlannerService()
    }
    func openListing(_ item: PlannerItem, locale: String) async -> Listing? {
        guard !isOpeningListing else { return nil }
        let token = generation
        isOpeningListing = true
        routeError = nil
        defer { if token == generation { isOpeningListing = false } }
        do {
            let listing = try await listingService.getListing(id: item.listingId, locale: locale)
            guard generation == token, !Task.isCancelled else { return nil }
            return listing
        } catch {
            if generation == token, !(error is CancellationError) { routeError = error.localizedDescription }
            return nil
        }
    }

    func makeBooking(for item: PlannerItem, listing: Listing, locale: String) -> BookingViewModel {
        let form = BookingViewModel(listingID: item.listingId, slug: listing.slug ?? item.slug, type: listing.type, locale: locale)
        form.listing = listing
        form.adults = session?.answers.guests?.adults ?? 1
        form.children = session?.answers.guests?.children ?? 0
        if let dates = item.dates {
            // Booking uses local calendar dates; preserve the planner's date components.
            let formatter = PlannerValues.formatter()
            formatter.timeZone = .current
            form.checkIn = formatter.date(from: dates.checkIn) ?? form.checkIn
            form.checkOut = formatter.date(from: dates.checkOut) ?? form.checkOut
        }
        form.preferredSessionId = item.session?.id
        return form
    }

    func selectDestination(_ id: String?) async { cityId = id; await submit() }

    func toggleInterest(_ id: String?) {
        guard let id else { interests.removeAll(); return }
        if interests.contains(id) { interests.remove(id) }
        else if interests.count < min(20, session?.input.constraints?.maxSelections ?? 20) { interests.insert(id) }
    }

    var adultRange: ClosedRange<Int> { 1...max(1, (session?.input.constraints?.maxTotal ?? 100) - children) }
    var childrenRange: ClosedRange<Int> { 0...max(0, (session?.input.constraints?.maxTotal ?? 100) - adults) }

    func belongs(to userID: String?) -> Bool {
        account == userID && userID != nil
    }

    func load(account: String?, locale: String) async {
        let changed = self.account != account
        generation = UUID()
        isLoading = false
        isOpeningListing = false
        routeError = nil
        errorMessage = nil
        needsNewSession = false
        fieldErrors = [:]
        self.account = account
        self.locale = locale
        if changed {
            optionLabels = [:]
            session = nil
            items = []
            alternatives = []
            clearDraft()
        }
        guard let account else {
            errorMessage = String(localized: "planner.login")
            return
        }
        if let id = sessionStorage.sessionID(for: account) {
            await perform(.get(id, locale, 1), preserveDraft: !changed)
        } else {
            await perform(.create(locale))
        }
    }
    func start() async {
        guard !isLoading, account != nil else { return }
        await perform(.create(locale))
    }
    func sync() async {
        guard !isLoading, let session else {
            await start()
            return
        }
        await perform(.get(session.sessionId, locale, 1), preserveDraft: true)
    }
    func submit() async {
        guard !isLoading, !needsNewSession, let s = session else { return }
        let answer: PlannerAnswer
        switch s.currentStep {
        case "destination":
            guard
                s.input.options?.contains(where: { $0.value == cityId }) == true
            else { return }
            answer = .destination(cityId)
        case "dates":
            let nights =
                PlannerValues.calendar.dateComponents(
                    [.day],
                    from: checkIn,
                    to: checkOut
                ).day ?? 0
            guard checkIn >= PlannerValues.calendar.startOfDay(for: Date()),
                nights > 0,
                nights <= min(30, s.input.constraints?.maxNights ?? 30)
            else {
                errorMessage = String(localized: "planner.invalidDates")
                return
            }
            answer = .dates(
                PlannerValues.string(checkIn),
                PlannerValues.string(checkOut)
            )
        case "guests":
            guard adults >= 1, children >= 0,
                adults + children <= (s.input.constraints?.maxTotal ?? Int.max)
            else {
                errorMessage = String(localized: "planner.invalidGuests")
                return
            }
            answer = .guests(adults, children)
        case "budget":
            guard let value = PlannerValues.amount(amount) else {
                errorMessage = String(localized: "planner.invalidAmount")
                return
            }
            answer = .budget(value)
        case "interests":
            guard
                interests.count
                    <= min(20, s.input.constraints?.maxSelections ?? 20)
            else { return }
            answer = .interests(interests.sorted())
        case "review": answer = .review
        default: return
        }
        await perform(
            .answer(
                s.sessionId,
                locale,
                .init(version: s.version, step: s.currentStep, answer: answer)
            ),
            mutation: true
        )
    }
    func back() async {
        guard !isLoading, let s = session, s.canGoBack else { return }
        await perform(
            .back(s.sessionId, locale, .init(version: s.version)),
            mutation: true
        )
    }
    var suggestedSteps: [String] {
        func strings(_ value: JSONValue) -> [String] {
            switch value {
            case .string(let text): return [text.lowercased()]
            case .array(let values): return values.flatMap(strings)
            case .object(let values):
                return values.keys.map { $0.lowercased() }
                    + values.values.flatMap(strings)
            default: return []
            }
        }
        let text = (session?.results?.suggestedChanges ?? []).flatMap(strings)
            .joined(separator: " ")
        return ["destination", "dates", "budget", "interests"].filter { step in
            text.contains(step) || (step == "dates" && text.contains("date"))
                || (step == "destination" && text.contains("city"))
                || (step == "interests" && text.contains("categor"))
        }
    }
    func rewind(to target: String) async {
        let token = generation
        for _ in 0..<7 {
            guard generation == token, let current = session,
                current.currentStep != target,
                current.canGoBack, !isLoading
            else { return }
            await back()
            guard session?.version != current.version, errorMessage == nil
            else { return }
        }
    }
    func reset() async {
        guard !isLoading, !needsNewSession, let s = session else { return }
        await perform(
            .reset(s.sessionId, locale, .init(version: s.version)),
            mutation: true
        )
    }
    func more() async {
        guard !isLoading, let s = session, let meta = s.results?.meta,
            meta.hasNextPage
        else { return }
        await perform(.get(s.sessionId, locale, meta.page + 1), append: true)
    }
    private func perform(
        _ endpoint: TravelPlannerEndpoint,
        preserveDraft: Bool = false,
        mutation: Bool = false,
        append: Bool = false
    ) async {
        let token = generation
        isLoading = true
        errorMessage = nil
        needsNewSession = false
        fieldErrors = [:]
        defer { if generation == token { isLoading = false } }
        do {
            let result = try await service.request(endpoint)
            guard generation == token, !Task.isCancelled else { return }
            apply(
                result,
                preserveDraft: preserveDraft
                    && result.version == session?.version,
                append: append
            )
        } catch {
            guard generation == token else { return }
            if error is CancellationError { return }
            fieldErrors = (error as? APIRequestFailure)?.fieldErrors ?? [:]
            let code = (error as? APIRequestFailure)?.error.code
            if ["NOT_FOUND", "PLANNER_SESSION_EXPIRED"].contains(code ?? "") {
                needsNewSession = true
                session = nil
                items = []
                alternatives = []
                if let account { sessionStorage.remove(for: account) }
            }
            errorMessage =
                code == "FORBIDDEN"
                ? String(localized: "planner.customerOnly")
                : error.localizedDescription
            // A failed POST may have committed. Reconcile before allowing another submit.
            if mutation || code == "CONFLICT", let id = session?.sessionId,
                let result = try? await service.request(.get(id, locale, 1)),
                generation == token
            {
                apply(
                    result,
                    preserveDraft: result.version == session?.version,
                    append: false
                )
            }
        }
    }
    private func clearDraft() {
        cityId = nil
        adults = 1
        children = 0
        amount = ""
        interests = []
        checkIn = PlannerValues.calendar.startOfDay(for: Date())
        checkOut = PlannerValues.calendar.date(
            byAdding: .day,
            value: 1,
            to: checkIn
        )!
    }
    private func apply(_ s: PlannerSession, preserveDraft: Bool, append: Bool) {
        if session?.sessionId != s.sessionId { optionLabels = [:] }
        for option in s.input.options ?? [] {
            if let id = option.value { optionLabels[id] = option.label }
        }
        session = s
        if let account { sessionStorage.save(s.sessionId, for: account) }
        if !preserveDraft {
            clearDraft()
            cityId = s.answers.destination?.cityId
            if let dates = s.answers.dates {
                checkIn = PlannerValues.date(dates.checkIn) ?? checkIn
                checkOut = PlannerValues.date(dates.checkOut) ?? checkOut
            }
            adults = s.answers.guests?.adults ?? 1
            children = s.answers.guests?.children ?? 0
            amount = s.answers.budget?.amount ?? ""
            interests = Set(s.answers.interests?.categoryIds ?? [])
        }
        if !append {
            items = []
            alternatives = []
        }
        if let results = s.results {
            var seen = Set((items + alternatives).map(\.listingId))
            for item in results.items where seen.insert(item.listingId).inserted
            { items.append(item) }
            for item in results.alternatives
            where seen.insert(item.listingId).inserted {
                alternatives.append(item)
            }
        }
    }
    var bubbles: [String] {
        guard let s = session else { return [] }
        var result: [String] = []
        if s.answers.destination != nil {
            result.append(
                s.summary?.destination ?? s.answers.destination?.cityId.map {
                    optionLabels[$0] ?? $0
                } ?? String(localized: "planner.any")
            )
        }
        if let d = s.answers.dates {
            result.append("\(d.checkIn) → \(d.checkOut)")
        }
        if let g = s.answers.guests {
            result.append(
                "\(String(localized: "planner.adults")): \(g.adults), \(String(localized: "planner.children")): \(g.children)"
            )
        }
        if let b = s.answers.budget {
            result.append("\(b.amount) \(b.currency)")
        }
        if s.answers.interests != nil {
            result.append(
                s.summary?.interests?.joined(separator: ", ").nilIfEmpty ?? s
                    .answers.interests?.categoryIds.map {
                        optionLabels[$0] ?? $0
                    }.joined(separator: ", ").nilIfEmpty
                    ?? String(localized: "planner.any")
            )
        }
        return result
    }
}
extension String {
    fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
