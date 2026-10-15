import SwiftUI

struct BookingListView: View {
    @State private var viewModel: BookingListViewModel
    @State private var actionBooking: BookingsModel?
    @State private var pendingAction: ProviderBookingAction?

    init(role: RoleEnum, service: BookingServiceProtocol? = nil) {
        _viewModel = State(
            initialValue: BookingListViewModel(role: role, service: service)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.role == .customer || viewModel.role == .provider {
                Picker("listing.detail.status", selection: $viewModel.status) {
                    Text("booking.allStatuses").tag(nil as String?)
                    ForEach(BookingStatus.allCases) {
                        Text($0.title).tag(Optional($0.rawValue))
                    }
                }.pickerStyle(.menu).padding(.horizontal)
                    .onChange(of: viewModel.status) { _, _ in
                        Task { await viewModel.loadBookings() }
                    }
            }
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView()
                case .error(let message):
                    ErrorStateView(title: "error.title", message: message) {
                        Task { await viewModel.loadBookings() }
                    }
                case .loaded:
                    if viewModel.bookings.isEmpty {
                        ScrollView {
                            ContentUnavailableView(
                                "bookings.emptyTitle",
                                systemImage: "calendar.badge.exclamationmark"
                            )
                            if let error = viewModel.error {
                                Text(error).foregroundStyle(Color.errorColor)
                            }
                        }.refreshable {
                            await viewModel.loadBookings(isRefreshing: true)
                        }
                    } else {
                        bookingsList
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: .bookingsChanged))
        { event in
            if viewModel.role == .provider {
                viewModel.applyProviderChange(event.object as? BookingsModel)
            }
            Task { await viewModel.loadBookings(isRefreshing: true) }
        }
        .confirmationDialog(
            pendingAction?.confirmation ?? "provider.booking.confirmPrompt",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: {
                    if !$0 {
                        pendingAction = nil
                        actionBooking = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction, let booking = actionBooking {
                Button(
                    action.title(for: booking),
                    role: action == .cancel ? .destructive : nil
                ) {
                    Task {
                        await viewModel.performProviderAction(
                            action,
                            booking: booking
                        )
                    }
                }
            }
            Button("common.cancel", role: .cancel) {
                pendingAction = nil
                actionBooking = nil
            }
        }
        .alert(
            "error.title",
            isPresented: Binding(
                get: { viewModel.providerActions.error != nil },
                set: { if !$0 { viewModel.providerActions.error = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) {
                viewModel.providerActions.error = nil
            }
        } message: {
            Text(viewModel.providerActions.error ?? "")
        }
        .navigationTitle("bookings.title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBookings()
        }
    }

    private var bookingsList: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            List {
                ForEach(viewModel.bookings) { booking in
                    NavigationLink {
                        BookingDetailView(
                            bookingID: booking.id,
                            role: viewModel.role
                        )
                    } label: {
                        BookingListItemView(
                            booking: booking,
                            isBusy: viewModel.providerActions.busyID
                                == booking.id
                        )
                    }
                    .listRowBackground(Color.appBackground)
                    .listRowInsets(
                        EdgeInsets(
                            top: 16,
                            leading: 20,
                            bottom: 16,
                            trailing: 16
                        )
                    )
                    .listRowSeparatorTint(Color.borderColor)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if viewModel.role == .provider {
                            ForEach(
                                booking.providerActions(now: timeline.date)
                                    .filter { $0 != .cancel }
                            ) { action in
                                swipeButton(action, booking: booking)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if viewModel.role == .provider,
                            booking.providerActions(now: timeline.date)
                                .contains(.cancel)
                        {
                            swipeButton(.cancel, booking: booking)
                        }
                    }
                    .contextMenu {
                        if viewModel.role == .provider {
                            ForEach(booking.providerActions(now: timeline.date))
                            { action in
                                swipeButton(action, booking: booking)
                            }
                        }
                    }
                }
                if viewModel.role != .admin, viewModel.pagination.hasMore {
                    HStack {
                        Spacer()
                        Button("reviews.loadMore") {
                            Task { await viewModel.loadMore() }
                        }
                        if viewModel.pagination.isLoading { ProgressView() }
                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .disabled(viewModel.pagination.isLoading)
                    .listRowBackground(Color.appBackground)
                    .listRowSeparator(.hidden)
                }
                if let error = viewModel.error {
                    Text(error).foregroundStyle(Color.errorColor)
                        .listRowBackground(Color.appBackground)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .refreshable { await viewModel.loadBookings(isRefreshing: true) }
        }
    }

    private func swipeButton(
        _ action: ProviderBookingAction,
        booking: BookingsModel
    ) -> some View {
        // Keep cancellation non-destructive here so the row stays until confirmation succeeds.
        Button {
            actionBooking = booking
            pendingAction = action
        } label: {
            Label(
                action.title(for: booking),
                systemImage: action == .confirm
                    ? "checkmark"
                    : action == .complete ? "checkmark.seal" : "xmark"
            )
        }
        .tint(action == .cancel ? .red : action == .confirm ? .green : .blue)
        .disabled(viewModel.providerActions.busyID != nil)
    }
}

struct BookingListItemView: View {
    let booking: BookingsModel
    var isBusy = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImageView(path: booking.listing.coverImageUrl) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.surfaceBackground)
                    .overlay {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.descriptionText)
                    }
            }
            .frame(width: 56, height: 56)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(booking.listing.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.titleText)
                    .lineLimit(2)
                Text(booking.reference)
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.descriptionText)
                Label(booking.schedule, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.descriptionText)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label(String(booking.participants), systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(Color.descriptionText)
                    Spacer(minLength: 8)
                    Text(
                        "\(booking.totalAmount.formatted(.number.precision(.fractionLength(0...2)))) \(booking.currency)"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.titleText)
                    .fixedSize(horizontal: true, vertical: false)
                }
                HStack(spacing: 6) {
                    Label(booking.statusTitle, systemImage: booking.statusIcon)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor)
                    if isBusy { ProgressView().controlSize(.mini) }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch booking.status.uppercased() {
        case "CONFIRMED", "COMPLETED": .green
        case "PENDING": .orange
        case "CANCELLED": .red
        default: Color.descriptionText
        }
    }
}
