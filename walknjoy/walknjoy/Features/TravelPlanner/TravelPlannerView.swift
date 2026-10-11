import SwiftUI

@MainActor
struct TravelPlannerView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var budgetFocused: Bool
    @State private var model = TravelPlannerViewModel()
    @State private var confirmReset = false
    @State private var detail: Listing?
    @State private var booking: BookingViewModel?
    @State private var pendingBookingID: String?
    @State private var createdBookingID: String?
    private var locale: String { appState.language.rawValue }
    private var identity: String { "\(appState.currentUserID ?? ""):\(locale)" }
    private let steps = [
        "destination", "dates", "guests", "budget", "interests", "review",
        "results",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let s = model.session,
                    model.belongs(to: appState.currentUserID)
                {
                    Text(
                        String(localized: "planner.step")
                            + " \((steps.firstIndex(of: s.currentStep) ?? 0) + 1)/7"
                    )
                    .font(.caption).foregroundStyle(Color.description)
                    ForEach(Array(model.bubbles.enumerated()), id: \.offset) {
                        _,
                        text in
                        TravelPlannerChatBubble(text: text, user: true)
                    }
                    TravelPlannerChatBubble(text: s.message, user: false)
                    if s.currentStep == "results" {
                        TravelPlannerResultsView(s: s, model: model) { item, book in
                            Task { await open(item, book: book) }
                        }
                    } else {
                        TravelPlannerInputPanel(s: s, model: model, budgetFocused: $budgetFocused)
                    }
                }
                if model.isLoading {
                    HStack {
                        ProgressView()
                        Text(
                            model.session?.currentStep == "review"
                                ? "planner.checking" : "planner.loading"
                        )
                    }
                }
                if let error = model.errorMessage {
                    Text(
                        appState.currentUserID != nil
                            && appState.currentUserRole != .customer
                            ? String(localized: "planner.customerOnly") : error
                    ).foregroundStyle(.red)
                    Button(
                        model.needsNewSession ? "planner.start" : "common.retry"
                    ) {
                        Task {
                            if model.needsNewSession {
                                await model.start()
                            } else {
                                await model.sync()
                            }
                        }
                    }.disabled(model.isLoading)
                }
                if let error = model.routeError { Text(error).foregroundStyle(.red) }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBg)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let session = model.session,
                model.belongs(to: appState.currentUserID)
            {
                TravelPlannerActionBar(session: session, isLoading: model.isLoading,
                    onBack: { budgetFocused = false; Task { await model.back() } },
                    onContinue: { budgetFocused = false; Task { await model.submit() } })
            }
        }
        .navigationTitle("planner.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("planner.restart") { confirmReset = true }.disabled(
                    model.isLoading || model.session == nil
                )
            }
        }
        .confirmationDialog(
            "planner.resetConfirm",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("planner.restart", role: .destructive) {
                Task { await model.reset() }
            }
            Button("common.cancel", role: .cancel) {}
        }
        .task(id: identity) {
            await model.load(
                account: appState.currentUserRole == .customer
                    ? appState.currentUserID : nil,
                locale: locale
            )
        }
        .onChange(of: appState.currentUserID) { _, _ in
            detail = nil
            booking = nil
            pendingBookingID = nil
            createdBookingID = nil
        }
        .navigationDestination(
            isPresented: Binding(
                get: { detail != nil },
                set: { if !$0 { detail = nil } }
            )
        ) {
            if let detail { ListingDetailView(listing: detail) }
        }
        .sheet(
            item: $booking,
            onDismiss: {
                createdBookingID = pendingBookingID
                pendingBookingID = nil
            }
        ) { form in
            BookingFormView(
                viewModel: form,
                onSuccess: { result in
                    pendingBookingID = result.id
                    NotificationCenter.default.post(
                        name: .bookingsChanged,
                        object: nil
                    )
                }
            )
        }
        .navigationDestination(item: $createdBookingID) { id in
            BookingDetailView(bookingID: id, role: .customer)
        }
    }

    private func open(_ item: PlannerItem, book: Bool) async {
        guard let listing = await model.openListing(item, locale: locale) else { return }
        if book { booking = model.makeBooking(for: item, listing: listing, locale: locale) }
        else { detail = listing }
    }
}
