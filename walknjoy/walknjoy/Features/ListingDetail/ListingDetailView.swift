import SwiftUI

struct ListingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    private let data: PublicListing?
    private let previewListing: Listing?
    @State private var model = ListingDetailViewModel()
    @State private var contentLocale: String?
    @State private var bookingModel: BookingViewModel?
    @State private var createdBookingID: String?
    @State private var pendingBookingID: String?
    @State private var favoriteError: String?
    @State private var showConversation = false

    private var listing: Listing? { previewListing ?? model.listing }
    private let rating: Rating?
    private let initialFavorite: Bool
    private let onFavorite: (() -> Void)?
    private let onBook: (() -> Void)?

    private var title: String { listing?.title ?? "" }
    private var listingID: String { data?.id ?? listing?.id ?? "" }
    private var slug: String { listing?.slug ?? data?.slug ?? "" }
    private var currentRating: Rating? {
        appState.reviews.rating(
            for: listingID,
            fallback: listing?.rating ?? rating
        )
    }
    private var shortDescription: String? { listing?.shortDescription }
    private var type: ListingType { listing?.type ?? .stay }
    private var location: ListingLocation? { listing?.location }
    private var localeCode: String {
        contentLocale ?? appState.language.rawValue
    }

    /// Canlı favorite vəziyyəti: appState-dən oxunur, ona görə düymə dərhal yenilənir.
    private var isFavorite: Bool {
        if let data { return appState.isFavorite(data) }
        return initialFavorite
    }
    private var isUpdatingFavorite: Bool {
        appState.updatingFavoriteIDs.contains(listingID)
    }

    private var imagePaths: [String] {
        if let listing {
            return listing.media.filter { $0.type == "image" }
                .sorted { left, right in
                    if left.isCover != right.isCover { return left.isCover }
                    return left.order < right.order
                }.map(\.url)
        }
        if let cover = data?.coverMedia, cover.type == .image {
            return [cover.url]
        }
        return []
    }

    init(
        data: PublicListing,
        isFavorite: Bool? = nil,
        detailService: (any ListingDetailServiceProtocol)? = nil,
        onFavorite: (() -> Void)? = nil,
        onBook: (() -> Void)? = nil
    ) {
        self.data = data
        previewListing = nil
        rating = data.rating
        initialFavorite = isFavorite ?? data.isFavorite
        _model = State(
            initialValue: ListingDetailViewModel(service: detailService)
        )
        self.onFavorite = onFavorite
        self.onBook = onBook
    }

    init(
        listing: Listing,
        rating: Rating? = nil,
        isFavorite: Bool = false,
        onFavorite: (() -> Void)? = nil,
        onBook: (() -> Void)? = nil
    ) {
        data = nil
        self.previewListing = listing
        self.rating = rating
        initialFavorite = isFavorite
        self.onFavorite = onFavorite
        self.onBook = onBook
    }

    // MARK: - Body

    var body: some View {
        Group {
            if model.notFound || ListingLifecycle.shared.deletedIDs.contains(listingID) {
                ContentUnavailableView("listing.detail.notFound", systemImage: "magnifyingglass")
            } else if listing != nil {
                detailContent
            } else if case .error(let message) = model.state {
                ErrorStateView(title: "error.title", message: message) {
                    Task { await load() }
                }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.iconColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(listing != nil)
        .toolbar {
            if listing != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        ListingHeaderActionLabel(symbol: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("common.back"))
                }
                .sharedBackgroundVisibility(.hidden)
            }
            if appState.canUseFavorites {
                ToolbarItem(placement: .topBarTrailing) {
                    favoriteButton
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: .listingsChanged)) { _ in
            Task { await load() }
        }
        .task(id: appState.reviews.revision) { await load() }
        .onChange(of: model.notFound) { _, notFound in
            if notFound { ListingLifecycle.shared.didDelete(listingID) }
        }
        .onChange(of: appState.language) { _, _ in dismiss() }
        .navigationDestination(isPresented: $showConversation) {
            ConversationStartView(context: .listing(listingID))
        }
        .sheet(
            item: $bookingModel,
            onDismiss: {
                createdBookingID = pendingBookingID
                pendingBookingID = nil
            }
        ) { bookingModel in
            BookingFormView(
                viewModel: bookingModel,
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
        .alert(
            "favorites.error",
            isPresented: Binding(
                get: { favoriteError != nil },
                set: { if !$0 { favoriteError = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { favoriteError = nil }
        } message: {
            Text(favoriteError ?? "")
        }
    }

    // MARK: - Favorite

    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            ListingHeaderActionLabel(
                symbol: isFavorite ? "heart.fill" : "heart",
                tint: isFavorite ? Color.errorC : Color.titleText,
                isLoading: isUpdatingFavorite
            )
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingFavorite)
        .accessibilityLabel(isFavorite ? "favorites.remove" : "favorites.add")
        .animation(.spring(duration: 0.25), value: isFavorite)
    }

    private func toggleFavorite() {
        if let onFavorite {
            onFavorite()
            return
        }
        guard let data else { return }
        Task {
            do {
                try await appState.setFavorite(
                    !appState.isFavorite(data),
                    for: data
                )
            } catch {
                favoriteError = error.localizedDescription
            }
        }
    }

    // MARK: - Loading

    private func load() async {
        guard previewListing == nil else { return }
        let locale = appState.language.rawValue
        contentLocale = locale
        if !appState.hasLoadedCurrentUserRole {
            await appState.loadFavoriteAccess()
        }
        guard !Task.isCancelled, locale == appState.language.rawValue else {
            return
        }
        await model.load(
            slug: data?.slug ?? "",
            locale: locale,
            includeCustomerToken: appState.currentUserRole == .customer
        )
    }

    // MARK: - Content

    private var detailContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ListingGalleryView(
                    imagePaths: imagePaths,
                    height: 300,
                    bottomInset: 22
                )

                VStack(alignment: .leading, spacing: 20) {
                    ListingHeaderView(
                        title: title,
                        category: listing?.category?.name,
                        type: type,
                        shortDescription: shortDescription,
                        rating: currentRating,
                        location: location
                    )

                    if let description = listing?.description,
                        !description.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    {
                        detailPanel {
                            ListingDescriptionView(description: description)
                        }
                    }

                    if !(listing?.amenities ?? []).isEmpty {
                        detailPanel {
                            ListingAmenitiesView(
                                amenities: listing?.amenities ?? []
                            )
                        }
                    }

                    if let details = listing?.details {
                        switch details {
                        case .stay(let value): StayDetailsView(details: value)
                        case .tour(let value): TourDetailsView(details: value)
                        case .activity(let value):
                            ActivityDetailsView(details: value)
                        case .experience(let value):
                            ExperienceDetailsView(details: value)
                        }
                    }

                    if let location {
                        detailPanel { locationSection(location) }
                    }

                    if appState.currentUserRole == .customer {
                        Button {
                            showConversation = true
                        } label: {
                            Label(
                                "messages.contactProvider",
                                systemImage: "bubble.left.and.bubble.right"
                            )
                            .font(.headline).frame(
                                maxWidth: .infinity,
                                minHeight: 48
                            )
                            .background(
                                Color.surfaceBackground,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }.buttonStyle(.plain)
                    }
                    detailPanel { reviewsSection }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appBackground)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 26,
                        topTrailingRadius: 26
                    )
                )
                .padding(.top, -22)
            }
        }
        .background(Color.appBackground)
        .ignoresSafeArea(.container, edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ListingBookingBar(
                price: listing?.basePrice ?? 0,
                currency: listing?.currency ?? "AZN",
                type: type,
                showsBookingButton: appState.currentUserRole == .customer,
                onBook: {
                    let form = BookingViewModel(
                        listingID: listingID,
                        slug: slug,
                        type: type,
                        locale: localeCode
                    )
                    form.listing = listing
                    bookingModel = form
                }
            )
        }
        .accessibilityIdentifier(
            "listing-detail-\(data?.slug ?? listing?.slug ?? listing?.id ?? "")"
        )
    }

    private func detailPanel<Content: View>(@ViewBuilder content: () -> Content)
        -> some View
    {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.surfaceBackground,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20).stroke(
                    Color.borderColor.opacity(0.45),
                    lineWidth: 1
                )
            }
    }

    private func locationSection(_ location: ListingLocation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ListingLocationView(location: location)

            if location.latitude != nil, location.longitude != nil {
                ListingMapView(
                    listings: [
                        PublicListing(
                            id: listingID,
                            type: type,
                            title: title,
                            slug: slug,
                            basePrice: listing?.basePrice ?? 0,
                            currency: listing?.currency ?? "AZN",
                            location: location,
                            rating: currentRating
                                ?? Rating(average: nil, count: 0)
                        )
                    ],
                    selection: .constant(nil)
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.border, lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private var reviewsSection: some View {
        if let slug = ReviewValidation.text(listing?.slug ?? data?.slug) {
            ListingReviewsSection(
                listingID: listingID,
                slug: slug,
                locale: localeCode,
                rating: currentRating
            )
            .id(slug + "|" + localeCode)
        } else {
            ListingReviewsView(rating: currentRating)
        }
    }
}
