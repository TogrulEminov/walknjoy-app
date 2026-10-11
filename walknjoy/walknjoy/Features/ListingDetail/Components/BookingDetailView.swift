import SwiftUI

struct BookingDetailView: View {
    @Environment(AppState.self) private var appState
    let bookingID: String
    let role: RoleEnum
    @State private var model: BookingDetailViewModel
    @State private var showTicket = false
    @State private var showConversation = false
    @State private var confirmCancel = false
    @State private var confirmDelete = false
    @State private var editor: ReviewEditorContext?

    init(
        bookingID: String,
        role: RoleEnum,
        service: BookingServiceProtocol? = nil
    ) {
        self.bookingID = bookingID
        self.role = role
        _model = State(
            initialValue: BookingDetailViewModel(
                bookingID: bookingID,
                role: role,
                service: service
            )
        )
    }

    private var isFavorite: Bool {
        guard let listingID = model.booking?.listing.id else { return false }
        return appState.favoriteOverrides[listingID]
            ?? (model.booking?.listing.isFavorite ?? false)
    }

    private func toggleFavorite() {
        guard let listing = model.booking?.listing else { return }
        Task {
            do {
                try await appState.setFavorite(
                    !isFavorite,
                    listingID: listing.id
                )
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }

    var body: some View {
        Group {
            if case .loading = model.state {
                LoadingStateView()
            } else if let booking = model.booking {
                ScrollView {
                    VStack(spacing: 24) {
                        BookingHeaderView(booking: booking)
                        Button { Task { await model.openListing(locale: appState.language.rawValue) } } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                if let image = booking.listing.coverImageUrl {
                                    RemoteImageView(path: image) { Color.surfaceBackground }
                                        .frame(height: 160).clipped().clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                Label(booking.listing.title, systemImage: "house")
                                    .font(.headline).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                        }.padding(.horizontal)

                        VStack(alignment: .leading, spacing: 16) {
                            BookingDetailSection(
                                title: "listing.detail.general"
                            ) {
                                BookingDetailRow(
                                    title: "listing.detail.reference",
                                    value: booking.reference
                                )
                                BookingDetailRow(
                                    title: "listing.detail.status",
                                    value: booking.statusTitle
                                )
                            }

                            BookingDetailSection(title: "listing.detail.dates")
                            {
                                if booking.session != nil {
                                    BookingDetailRow(title: "booking.sessions.title", value: booking.schedule)
                                }
                                if let checkIn = booking.checkIn {
                                    BookingDetailRow(
                                        title: "listing.detail.checkIn",
                                        value: checkIn
                                    )
                                }
                                if let checkOut = booking.checkOut {
                                    BookingDetailRow(
                                        title: "listing.detail.checkOut",
                                        value: checkOut
                                    )
                                }
                            }

                            BookingDetailSection(
                                title: "listing.detail.details"
                            ) {
                                BookingDetailRow(
                                    title: "listing.detail.participants",
                                    value: "\(booking.participants)"
                                )
                                if let adults = booking.adults { BookingDetailRow(title: "listing.detail.adults", value: String(adults)) }
                                if let children = booking.children { BookingDetailRow(title: "listing.detail.children", value: String(children)) }
                                BookingDetailRow(
                                    title: "listing.detail.totalAmount",
                                    value:
                                        "\(booking.totalAmount.formatted(.number.precision(.fractionLength(0...2)))) \(booking.currency)"
                                )
                            }
                        }
                        .padding(.horizontal)

                        if let note = ReviewValidation.text(booking.customerNote) {
                            BookingDetailSection(title: "listing.detail.note") { Text(note) }.padding(.horizontal)
                        }
                        bookingDateRows(booking)
                        if role == .customer || role == .provider {
                            Button { showConversation = true } label: {
                                Label("messages.write", systemImage: "bubble.left.and.bubble.right")
                                    .font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 14))
                            }.padding(.horizontal)
                        }
                        if role == .customer, booking.canCancel {
                            Button("booking.cancel", role: .destructive) { confirmCancel = true }
                                .frame(minHeight: 44).disabled(model.isCancelling)
                            if model.isCancelling { ProgressView() }
                        }
                        if role == .customer, booking.status.uppercased() == "COMPLETED" {
                            ownReviewSection(booking).padding(.horizontal)
                        }
                        if role == .customer {
                            Button {
                                Task { await loadTicket() }
                            } label: {
                                Label(
                                    "listing.detail.downloadTicket",
                                    systemImage: "doc.fill"
                                )
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.brandInk)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    Color.brandYellow,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .background(Color.appBackground)
            } else if let error = model.error {
                ErrorStateView(title: "error.title", message: error) {
                    Task { await model.load() }
                }
            } else {
                ContentUnavailableView(
                    "listing.detail.bookingNotFound",
                    systemImage: "ticket"
                )
            }
        }
        .navigationTitle("listing.detail.bookingDetail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if role == .customer && appState.canUseFavorites {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(isFavorite ? .red : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(isPresented: $showConversation) {
            ConversationStartView(context: role == .provider ? .providerBooking(bookingID) : .booking(bookingID))
        }
        .sheet(isPresented: $showTicket) {
            if let pdfData = model.ticketData {
                NavigationStack { BookingTicketView(pdfData: pdfData) }
            }
        }
        .task {
            await model.load()
            await model.loadReview(store: appState.reviews)
        }
        .task(id: appState.reviews.revision) { await model.loadReview(store: appState.reviews) }
        .refreshable { await model.load(); await model.loadReview(store: appState.reviews) }
        .sheet(item: $editor) { ReviewEditorView(context: $0, onSuccess: { Task { await model.loadReview(store: appState.reviews) } }) }
        .navigationDestination(isPresented: Binding(get: { model.listingDestination != nil }, set: { if !$0 { model.listingDestination = nil } })) {
            if let listing = model.listingDestination { ListingDetailView(listing: listing) }
        }
        .confirmationDialog("booking.cancelConfirm", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("booking.cancel", role: .destructive) { Task { await model.cancel() } }
            Button("common.cancel", role: .cancel) {}
        }
        .confirmationDialog("reviews.deleteConfirm", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("reviews.delete", role: .destructive) { Task { await model.deleteReview(store: appState.reviews) } }
        }
        .alert("error.title", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("common.ok", role: .cancel) {}
        } message: { Text(model.error ?? "") }
    }

    @ViewBuilder
    private func bookingDateRows(_ booking: BookingsModel) -> some View {
        let bookingDates: [(title: LocalizedStringKey, date: String?)] = [
            ("booking.confirmedAt", booking.confirmedAt),
            ("booking.cancelledAt", booking.cancelledAt),
            ("booking.completedAt", booking.completedAt),
        ]
        ForEach(Array(bookingDates.enumerated()), id: \.offset) { _, entry in
            if let date = entry.date {
                BookingDetailRow(
                    title: entry.title,
                    value: BookingsModel.timestamp(date)
                )
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder private func ownReviewSection(_ booking: BookingsModel) -> some View {
        BookingDetailSection(title: "booking.yourReview") {
            switch model.reviewState {
            case .idle, .loading: ProgressView()
            case .error(let message):
                Text(message).foregroundStyle(Color.errorColor)
                Button("common.retry") { Task { await model.loadReview(store: appState.reviews) } }
            case .loaded:
                if let review = model.ownReview {
                    ReviewCardView(name: booking.listing.title, rating: review.rating, title: review.title, comment: review.comment, date: review.createdAt, hidden: review.status == .hidden,
                                   onEdit: { editor = ReviewEditorContext(review) }, onDelete: { confirmDelete = true }, isBusy: model.isDeletingReview)
                } else {
                    Button("reviews.write") {
                        editor = ReviewEditorContext(listingID: booking.listing.id, slug: booking.listing.slug, bookingID: booking.id)
                    }.frame(minHeight: 44)
                }
            }
        }
    }

    private func loadTicket() async {
        await model.loadTicket()
        if model.ticketData != nil {
            showTicket = true
        }
    }
}

struct BookingHeaderView: View {
    let booking: BookingsModel
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandYellow.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "ticket.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.brandYellow)
            }

            Text(booking.reference)
                .font(.title2.bold())
                .foregroundStyle(Color.titleText)

            Label(booking.statusTitle, systemImage: booking.statusIcon)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.brandYellow.opacity(0.8), in: Capsule())
                .foregroundStyle(Color.brandInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct BookingDetailSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.descriptionText)
                .padding(.horizontal, 4)

            content
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
    }
}

struct BookingDetailRow: View {
    let title: LocalizedStringKey
    let value: String
    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(
                Color.descriptionText
            )
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(
                Color.titleText
            )
        }
    }
}
