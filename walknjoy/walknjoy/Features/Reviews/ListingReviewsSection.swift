import SwiftUI

struct ListingReviewsSection: View {
    @Environment(AppState.self) private var appState
    let listingID: String
    let slug: String
    let rating: Rating?
    @State private var model: ListingReviewsViewModel
    @State private var showAll = false
    @State private var allModel: ListingReviewsViewModel

    init(listingID: String, slug: String, locale: String, rating: Rating?) {
        self.listingID = listingID; self.slug = slug; self.rating = rating
        _model = State(initialValue: ListingReviewsViewModel(slug: slug, locale: locale))
        _allModel = State(initialValue: ListingReviewsViewModel(slug: slug, locale: locale))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ListingReviewsView(rating: appState.reviews.rating(for: listingID, fallback: rating))
                Button { showAll = true } label: {
                    HStack(spacing: 4) {
                        Text("reviews.all")
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }.tint(Color.titleText)
            }
            ratingRefreshState
            ListingReviewsContent(model: model, listingID: listingID, compact: true)
        }
        .task(id: appState.reviews.revision) {
            await model.refresh()
            await appState.reviews.refreshRating(listingID: listingID, slug: slug, locale: model.locale, service: model.service)
        }
        .sheet(isPresented: $showAll) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ListingReviewsView(rating: appState.reviews.rating(for: listingID, fallback: rating))
                        ratingRefreshState
                        ListingReviewsContent(model: allModel, listingID: listingID, compact: false)
                    }.padding(20)
                }
                .background(Color.appBackground)
                .refreshable { await allModel.refresh() }
                .task(id: appState.reviews.revision) { await allModel.refresh() }
                .navigationTitle("listing.detail.reviews").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("reviews.close") { showAll = false } } }
            }
        }
    }

    @ViewBuilder
    private var ratingRefreshState: some View {
        switch appState.reviews.ratingState(for: listingID) {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, alignment: .leading)
        case .error(let message):
            VStack(alignment: .leading, spacing: 8) {
                Text(message).font(.subheadline).foregroundStyle(Color.errorColor)
                Button("common.retry") {
                    Task {
                        await appState.reviews.refreshRating(
                            listingID: listingID, slug: slug,
                            locale: model.locale, service: model.service
                        )
                    }
                }
                .frame(minHeight: 44)
            }
        case .idle, .loaded:
            EmptyView()
        }
    }

}

struct ListingReviewsContent: View {
    @Environment(AppState.self) private var appState
    @Bindable var model: ListingReviewsViewModel
    let listingID: String
    let compact: Bool
    @State private var editor: ReviewEditorContext?
    @State private var pendingDelete: PublicReview?
    @State private var deletingID: String?
    @State private var error: String?
    @State private var eligibilityMessage: String?
    @State private var bookingChoices: [BookingsModel] = []
    @State private var choosingBooking = false
    @State private var showSuccess = false
    @State private var didSave = false
    private let bookingService: any BookingServiceProtocol = BookingService()

    private var ownContext: ReviewEditorContext? {
        if let own = appState.reviews.ownReviews[listingID] { return ReviewEditorContext(own) }
        if let own = model.pagination.items.first(where: { $0.author.id == appState.currentUserID }) {
            return ReviewEditorContext(own, listingID: listingID, slug: model.slug)
        }
        // Absence from this public page does not establish that the user has no review.
        return nil
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !compact {
                Picker("reviews.sort", selection: $model.sort) {
                    ForEach(ReviewSort.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.menu)
                .onChange(of: model.sort) { _, _ in Task { await model.refresh() } }
            }
            Button {
                Task { await prepareReview() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.pencil")
                    Text("reviews.write")
                    Spacer()
                    if model.checkingBookings { ProgressView() }
                    else { Image(systemName: "chevron.right").font(.caption.weight(.semibold)) }
                }
                .padding(.horizontal, 14).frame(minHeight: 48)
                .foregroundStyle(Color.titleText)
                .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1) }
            }
            .font(.subheadline.bold()).frame(minHeight: 44)
            .disabled(model.checkingBookings)
            if let eligibilityMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle").foregroundStyle(Color.iconColor)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("reviews.eligibilityTitle").font(.subheadline.weight(.semibold))
                        Text(eligibilityMessage).font(.subheadline).foregroundStyle(Color.descriptionText)
                        ForEach(model.relatedBookings.prefix(3)) { booking in
                            NavigationLink {
                                BookingDetailView(bookingID: booking.id, role: .customer)
                            } label: {
                                Label(booking.reference + " · " + booking.statusTitle, systemImage: booking.statusIcon)
                                    .font(.subheadline).frame(minHeight: 44)
                            }.tint(Color.titleText)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            }
            if let ownContext {
                Button("reviews.editOwn") { editor = ownContext }
                    .font(.subheadline).frame(minHeight: 44)
            }
            ForEach(compact ? Array(model.pagination.items.prefix(3)) : model.pagination.items) { review in
                ReviewCardView(name: review.author.firstName, avatar: review.author.avatarFile?.url,
                               rating: review.rating, title: review.title, comment: review.comment, date: review.createdAt, verified: review.verified == true,
                               onEdit: canManage(review) ? { editor = ReviewEditorContext(review, listingID: listingID, slug: model.slug) } : nil,
                               onDelete: canManage(review) ? { pendingDelete = review } : nil,
                               isBusy: deletingID == review.id)
            }
            ReviewLoadStateView(state: model.pagination.state, isEmpty: model.pagination.items.isEmpty) { Task { await model.refresh() } }
            if !compact, model.pagination.hasMore, !model.pagination.items.isEmpty, !model.pagination.isLoading {
                Button("reviews.loadMore") { Task { await model.pagination.loadNextPage() } }.frame(minHeight: 44)
            }
        }
        .sheet(item: $editor, onDismiss: {
            if didSave { didSave = false; showSuccess = true }
        }) { ReviewEditorView(context: $0, onSuccess: { didSave = true }) }
        .confirmationDialog("reviews.chooseBooking", isPresented: $choosingBooking, titleVisibility: .visible) {
            ForEach(bookingChoices) { booking in
                Button(booking.reference + " · " + (booking.checkIn ?? booking.completedAt ?? booking.createdAt)) {
                    editor = ReviewEditorContext(listingID: listingID, slug: model.slug, bookingID: booking.id)
                }
            }
            Button("common.cancel", role: .cancel) {}
        }
        .alert("reviews.saved", isPresented: $showSuccess) { Button("common.ok", role: .cancel) {} }
        .confirmationDialog("reviews.deleteConfirm", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
            if let review = pendingDelete {
                Button("reviews.delete", role: .destructive) { Task { await delete(review) } }
            }
            Button("common.cancel", role: .cancel) { pendingDelete = nil }
        } message: { Text("reviews.deleteMessage") }
        .alert("error.title", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("common.ok", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }
    private func prepareReview() async {
        eligibilityMessage = nil
        if !appState.hasLoadedCurrentUserRole { await appState.loadFavoriteAccess() }
        guard appState.currentUserID != nil else { appState.finishLogout(); return }
        guard appState.currentUserRole == .customer else {
            eligibilityMessage = String(localized: "reviews.customerOnly"); return
        }
        do {
            let choices = try await model.eligibleBookings(listingID: listingID, bookingService: bookingService, store: appState.reviews)
            guard !choices.isEmpty else {
                if let ownContext { editor = ownContext; return }
                eligibilityMessage = String(localized: "reviews.completedRequired")
                return
            }
            if choices.count == 1, let booking = choices.first {
                editor = ReviewEditorContext(listingID: listingID, slug: model.slug, bookingID: booking.id)
            } else {
                bookingChoices = choices
                choosingBooking = true
            }
        } catch is CancellationError {} catch { self.error = ReviewErrorMessage.text(error) }
    }

    private func canManage(_ review: PublicReview) -> Bool {
        appState.currentUserRole == .customer && review.author.id == appState.currentUserID
    }
    private func delete(_ review: PublicReview) async {
        guard deletingID == nil, canManage(review) else { return }
        deletingID = review.id
        let session = appState.reviews.sessionID
        defer { deletingID = nil }
        do {
            try await model.service.delete(id: review.id)
            guard session == appState.reviews.sessionID else { return }
            appState.reviews.changed(listingID: listingID, review: nil)
            await appState.reviews.refreshRating(listingID: listingID, slug: model.slug, locale: model.locale, service: model.service)
        } catch is CancellationError { }
        catch { self.error = ReviewErrorMessage.text(error) }
    }
}
