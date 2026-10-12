import SwiftUI

struct BookingListView: View {
    @State private var viewModel: BookingListViewModel

    init(role: RoleEnum, service: BookingServiceProtocol? = nil) {
        _viewModel = State(
            initialValue: BookingListViewModel(role: role, service: service)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.role == .customer {
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
                        }.refreshable { await viewModel.loadBookings() }
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
        { _ in
            Task { await viewModel.loadBookings() }
        }
        .navigationTitle("bookings.title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBookings()
        }
    }

    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.bookings) { booking in
                    NavigationLink(
                        value: ProfileDestination.bookingDetail(
                            id: booking.id,
                            role: viewModel.role
                        )
                    ) {
                        BookingListItemView(booking: booking)
                    }
                    .buttonStyle(.plain)
                }
                if viewModel.role == .customer, viewModel.pagination.hasMore {
                    Button("reviews.loadMore") {
                        Task { await viewModel.loadMore() }
                    }
                    .frame(minHeight: 44).disabled(
                        viewModel.pagination.isLoading
                    )
                }
                if let error = viewModel.error {
                    Text(error).foregroundStyle(Color.errorColor)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .refreshable { await viewModel.loadBookings() }
    }
}

struct BookingListItemView: View {
    let booking: BookingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let path = booking.listing.coverImageUrl {
                RemoteImageView(path: path) { Color.appBackground }
                    .frame(height: 140).clipped().clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
            }
            HStack {
                Text(booking.reference)
                    .font(.headline)
                    .foregroundStyle(Color.titleText)
                Spacer()
                statusBadge(status: booking.status)
            }

            HStack(spacing: 16) {
                Label(booking.schedule, systemImage: "calendar")
                Spacer()
                Label(
                    String(booking.participants),
                    systemImage: "person.2"
                )
            }
            .font(.caption)
            .foregroundStyle(Color.descriptionText)

            Divider().padding(.vertical, 8)

            HStack {
                Text(booking.listing.title)
                    .font(.subheadline)
                    .foregroundStyle(Color.titleText)
                Spacer()
                Text(
                    "\(booking.totalAmount.formatted(.number.precision(.fractionLength(0...2)))) \(booking.currency)"
                )
                .font(.subheadline.bold())
                .foregroundStyle(Color.brandInk)
            }
        }
        .padding()
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }

    private func statusBadge(status: String) -> some View {
        Label(booking.statusTitle, systemImage: booking.statusIcon)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status: status).opacity(0.2), in: Capsule())
            .foregroundStyle(statusColor(status: status))
    }

    private func statusColor(status: String) -> Color {
        switch status.lowercased() {
        case "confirmed", "completed": return .green
        case "pending": return .orange
        case "cancelled": return .red
        default: return .gray
        }
    }
}
