import Foundation
import Observation

@MainActor @Observable
final class BookingViewModel: Identifiable {
    let id = UUID()
    let listingID: String
    let slug: String
    let type: ListingType
    let locale: String
    let service: BookingServiceProtocol
    var listing: Listing?
    private(set) var availability: ListingAvailabilityResponse?

    var checkIn = Date()
    var checkOut = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    var selectedSessionId: String?
    var adults = 1
    var children = 0
    var customerNote = ""
    private(set) var sessions: [BookingSession] = []
    private(set) var sessionsState: LoadState<Void> = .idle
    var state: BookingState = .idle
    var error: String?
    var fieldErrors: [String: String] = [:]
    var bookingResult: BookingsModel?
    private var sessionsGeneration = UUID()
    private var lastRequest: BookingRequest?
    private var idempotencyKey = UUID().uuidString

    enum BookingState: Equatable {
        case idle, checkingAvailability, submitting, success, failed
    }

    init(listingID: String, slug: String, type: ListingType, locale: String, service: BookingServiceProtocol? = nil) {
        self.listingID = listingID
        self.slug = slug
        self.type = type
        self.locale = locale
        self.service = service ?? BookingService()
    }

    var isStay: Bool { type == .stay }
    var participants: Int { adults + children }
    var isBusy: Bool { state == .checkingAvailability || state == .submitting }
    var canBook: Bool {
        guard !isBusy, state != .success, adults >= 1, children >= 0, participants <= guestLimit else { return false }
        if isStay {
            let calendar = Calendar.current
            return calendar.startOfDay(for: checkIn) >= calendar.startOfDay(for: Date())
                && (calendar.dateComponents([.day], from: calendar.startOfDay(for: checkIn), to: calendar.startOfDay(for: checkOut)).day ?? 0) >= minimumNights
                && datesAvailable
        }
        guard case .loaded = sessionsState,
              let session = sessions.first(where: { $0.id == selectedSessionId }) else { return false }
        return canSelect(session)
    }

    var guestLimit: Int {
        switch listing?.details {
        case .stay(let details): return details.maxGuests
        case .tour(let details): return details.maxParticipants ?? 100
        case .activity(let details): return details.maxParticipants ?? 100
        case .experience(let details): return details.maxParticipants ?? 100
        case nil: return 100
        }
    }
    var minimumNights: Int {
        if case .stay(let details) = listing?.details { return max(1, details.minimumNights ?? 1) }
        return 1
    }
    var datesAvailable: Bool {
        guard let availability else { return false }
        let start = formatDate(checkIn), end = formatDate(checkOut)
        if let bound = availability.availableFrom, start < bound { return false }
        if let bound = availability.availableUntil, end > bound { return false }
        return !(availability.blockedPeriods ?? []).contains { start < $0.endDate && end > $0.startDate }
    }

    func canSelect(_ session: BookingSession) -> Bool {
        session.remaining >= participants && session.startsAt > Date()
    }

    func validateSelection() {
        fieldErrors = [:]
        if let selectedSessionId,
           !sessions.contains(where: { $0.id == selectedSessionId && canSelect($0) }) {
            self.selectedSessionId = nil
        }
    }

    func loadSessions() async {
        guard !isBusy else { return }
        sessionsGeneration = UUID()
        let generation = sessionsGeneration
        sessionsState = .loading
        selectedSessionId = nil
        do {
            let result = try await service.getListingAvailability(slug: slug, locale: locale)
            try Task.checkCancellation()
            guard generation == sessionsGeneration else { return }
            availability = result
            sessions = (result.sessions ?? []).sorted { $0.startsAt < $1.startsAt }
            sessionsState = .loaded(())
        } catch is CancellationError {
            if generation == sessionsGeneration { sessionsState = .idle }
        } catch {
            guard generation == sessionsGeneration else { return }
            sessionsState = .error(error.localizedDescription)
        }
    }

    func submitBooking(store: ReviewStore) async -> Bool {
        guard canBook else { return false }
        state = .checkingAvailability
        error = nil
        fieldErrors = [:]
        let request = BookingRequest(
            listingId: listingID,
            checkIn: isStay ? formatDate(checkIn) : nil,
            checkOut: isStay ? formatDate(checkOut) : nil,
            sessionId: isStay ? nil : selectedSessionId,
            adults: adults,
            children: children,
            customerNote: ReviewValidation.text(customerNote)
        )
        if request != lastRequest {
            lastRequest = request
            idempotencyKey = UUID().uuidString
        }
        let key = idempotencyKey
        do {
            let availability = try await service.checkAvailability(request: AvailabilityRequest(
                listingId: request.listingId,
                checkIn: request.checkIn,
                checkOut: request.checkOut,
                sessionId: request.sessionId,
                participants: isStay ? nil : request.adults + request.children
            ))
            try Task.checkCancellation()
            guard availability.available else {
                state = .failed
                error = availability.message ?? availability.reason.map { String(localized: String.LocalizationValue("booking.reason." + $0)) } ?? String(localized: "listing.detail.unavailable")
                return false
            }
            state = .submitting
            bookingResult = try await service.createBooking(request: request, idempotencyKey: key)
            state = .success
            return true
        } catch {
            state = .failed
            self.error = error.localizedDescription
            fieldErrors = (error as? APIRequestFailure)?.fieldErrors ?? [:]
            if let failure = error as? APIRequestFailure,
               ["SESSION_CAPACITY_EXCEEDED", "SESSION_NOT_AVAILABLE", "STAY_DATE_UNAVAILABLE"].contains(failure.error.code) {
                await loadSessions()
            }
            return false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
