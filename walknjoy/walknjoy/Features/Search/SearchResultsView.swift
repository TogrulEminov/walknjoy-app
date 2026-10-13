import MapKit
import SwiftUI

@MainActor
struct SearchResultsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: SearchViewModel
    @State private var showFilters = false
    @State private var quickFilter: QuickFilter?
    @State private var showMap = false
    @State private var selectedListingID: String?

    private enum QuickFilter: String, Identifiable {
        case destination
        case type

        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .destination: "search.destination"
            case .type: "search.type"
            }
        }
    }

    init(criteria: ListingSearchCriteria, viewModel: SearchViewModel? = nil) {
        _viewModel = State(
            initialValue: viewModel ?? SearchViewModel.makeDefault(criteria)
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if showMap {
                    ListingMapView(
                        listings: viewModel.visibleListings,
                        selection: $selectedListingID
                    )
                    .background(Color.appBg)
                } else {
                    listContent
                }
            }
            .navigationTitle("search.results.title")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.criteria.query,
                prompt: "home.search.placeholder"
            )
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .onChange(of: viewModel.criteria.query) { oldValue, newValue in
                if !oldValue.isEmpty && newValue.isEmpty {
                    Task { await viewModel.search() }
                }
            }
            .sheet(isPresented: $showFilters) {
                SearchFilterView(
                    criteria: viewModel.criteria,
                    categories: viewModel.categories,
                    amenities: viewModel.amenities
                ) { updated in
                    Task { await viewModel.applyFilters(updated) }
                }
                .presentationBackground(Color.appBackground)
            }
            .sheet(item: $quickFilter) { filter in
                quickFilterSheet(filter)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.appBackground)
            }
            .onReceive(NotificationCenter.default.publisher(for: .listingsChanged)) { event in
                if let id = event.object as? String { viewModel.invalidateDeletedListing(id) }
                Task { await viewModel.refresh(); await viewModel.loadDiscovery() }
            }
            .task(id: appState.language) {
                viewModel.criteria.locale = appState.language.rawValue
                async let discovery: Void = viewModel.loadDiscovery()
                async let search: Void = viewModel.search()
                _ = await (discovery, search)
            }
            .alert(
                "error.title",
                isPresented: Binding(
                    get: {
                        viewModel.error != nil && !viewModel.listings.isEmpty
                    },
                    set: { if !$0 { viewModel.error = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }

            if showMap,
                let selectedID = selectedListingID,
                let listing = viewModel.visibleListings.first(where: {
                    $0.id == selectedID
                })
            {
                mapSelectionCard(listing)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            mapToggle
                .padding(.bottom, 20)
        }
        .animation(.spring(), value: showMap)
        .animation(.spring(), value: selectedListingID)
    }

    // MARK: - List content

    private var listContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                summary
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                Group {
                    if viewModel.isInitialLoading && viewModel.listings.isEmpty
                    {
                        LoadingStateView()
                    } else if let error = viewModel.error,
                        viewModel.listings.isEmpty
                    {
                        ErrorStateView(title: "error.title", message: error) {
                            Task { await viewModel.search() }
                        }
                    } else if viewModel.listings.isEmpty {
                        ContentUnavailableView(
                            "search.empty.title",
                            systemImage: "magnifyingglass",
                            description: Text("search.empty.description")
                        )
                    } else {
                        results
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
        .background(Color.appBg)
        .refreshable {
            await Task { await viewModel.refresh() }.value
        }
    }

    // MARK: - Map

    @ViewBuilder
    private func mapSelectionCard(_ listing: PublicListing) -> some View {
        NavigationLink(value: AppRoute.listingDetails(listing)) {
            HStack(spacing: 12) {
                if let media = listing.coverMedia, media.type == .image,
                    let url = URL(string: media.url)
                {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.border.overlay {
                            Image(systemName: "photo").foregroundStyle(
                                Color.description
                            )
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.title)
                        .lineLimit(1)
                    Text(
                        "\(listing.basePrice.formatted(.number.precision(.fractionLength(0...2)))) \(listing.currency)"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(Color.button)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.description)
            }
            .padding()
            .background(Color.surfaceBg, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20).stroke(
                    Color.border,
                    lineWidth: 1
                )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .buttonStyle(.plain)
    }

    private var mapToggle: some View {
        Button {
            withAnimation { showMap.toggle() }
        } label: {
            Label(
                showMap ? "search.view.list" : "search.view.map",
                systemImage: showMap ? "list.bullet" : "map"
            )
            .font(.subheadline.bold())
            .foregroundStyle(Color.buttonTxt)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(Color.button, in: Capsule())
        }
        .buttonStyle(.plain)
        .shadow(radius: 4)
    }

    // MARK: - Results

    private var results: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.visibleListings) { listing in
                SearchListingRow(
                    listing: listing,
                    isFavorite: appState.isFavorite(listing),
                    isUpdatingFavorite: appState.updatingFavoriteIDs.contains(
                        listing.id
                    ),
                    canFavorite: appState.canUseFavorites,
                    onFavorite: {
                        Task {
                            do {
                                try await appState.setFavorite(
                                    !appState.isFavorite(listing),
                                    for: listing
                                )
                            } catch {
                                viewModel.error = error.localizedDescription
                            }
                        }
                    }
                )
            }

            if viewModel.canGoToPreviousPage || viewModel.canGoToNextPage {
                pagination
            } else if viewModel.isLoadingNextPage {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var pagination: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.goToPreviousPage()
            } label: {
                Label("search.pagination.previous", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        Color.surfaceBg,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(Color.border)
                    )
            }
            .disabled(
                !viewModel.canGoToPreviousPage || viewModel.isLoadingNextPage
            )
            .opacity(viewModel.canGoToPreviousPage ? 1 : 0.45)

            Text(
                String(
                    format: String(localized: "search.pagination.page"),
                    viewModel.currentPage
                )
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.description)
            .fixedSize()

            Button {
                Task { await viewModel.goToNextPage() }
            } label: {
                Group {
                    if viewModel.isLoadingNextPage {
                        ProgressView()
                    } else {
                        Label(
                            "search.pagination.next",
                            systemImage: "chevron.right"
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    Color.surfaceBg,
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Color.border)
                )
            }
            .disabled(!viewModel.canGoToNextPage || viewModel.isLoadingNextPage)
            .opacity(viewModel.canGoToNextPage ? 1 : 0.45)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.title)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        viewModel.criteria.destinationName
                            ?? String(localized: "search.allDestinations")
                    )
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.title)
                    .lineLimit(1)

                    Text(
                        String(
                            format: String(
                                localized: "search.resultCountFormat"
                            ),
                            viewModel.paginationMeta?.total ?? 0
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color.description)
                }
                Spacer(minLength: 8)
                Button {
                    showFilters = true
                } label: {
                    Label(
                        "search.filter.title",
                        systemImage: "slider.horizontal.3"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.buttonTxt)
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color.button, in: Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize()
                .accessibilityLabel("search.filter.title")
            }

            HStack(spacing: 8) {
                Button {
                    quickFilter = .destination
                } label: {
                    filterChip(
                        title: viewModel.criteria.destinationName
                            ?? String(localized: "search.allDestinations"),
                        systemImage: "mappin.and.ellipse"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("search.destination")
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    quickFilter = .type
                } label: {
                    filterChip(
                        title: viewModel.criteria.type.map(localizedTypeTitle)
                            ?? String(localized: "search.type.all"),
                        systemImage: "square.grid.2x2"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("search.type")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            Color.surfaceBg,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.border, lineWidth: 1)
        }
    }

    private func filterChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.button)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.title)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.description)
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(
            Color.appBg,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.border, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Quick filter sheet

    private func selectDestination(_ destinationID: String?) {
        var updatedCriteria = viewModel.criteria
        updatedCriteria.destinationId = destinationID
        updatedCriteria.destinationName =
            viewModel.destinations.first { $0.id == destinationID }?.city
        updatedCriteria.city = nil
        updatedCriteria.countryCode = nil

        Task { await viewModel.applyFilters(updatedCriteria) }
    }

    private func selectType(_ type: ListingType?) {
        var criteria = viewModel.criteria
        criteria.type = type
        criteria.categoryId = nil
        criteria.amenityIds = []
        Task { await viewModel.applyFilters(criteria) }
    }

    @ViewBuilder
    private func quickFilterSheet(_ filter: QuickFilter) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text(filter.title)
                        .font(.title3.bold())
                        .foregroundStyle(Color.title)

                    Spacer()

                    Button("common.close") { quickFilter = nil }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.button)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .background(Color.appBackground)

                ScrollView {
                    VStack(spacing: 8) {
                        switch filter {
                        case .destination:
                            Button {
                                selectDestination(nil)
                                quickFilter = nil
                            } label: {
                                selectionRow(
                                    title: String(
                                        localized: "search.allDestinations"
                                    ),
                                    selected: viewModel.criteria.destinationId
                                        == nil
                                )
                            }
                            .buttonStyle(.plain)

                            ForEach(viewModel.destinations) { destination in
                                Button {
                                    selectDestination(destination.id)
                                    quickFilter = nil
                                } label: {
                                    selectionRow(
                                        title: destination.city,
                                        selected: viewModel.criteria
                                            .destinationId == destination.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                        case .type:
                            Button {
                                selectType(nil)
                                quickFilter = nil
                            } label: {
                                selectionRow(
                                    title: String(localized: "search.type.all"),
                                    selected: viewModel.criteria.type == nil
                                )
                            }
                            .buttonStyle(.plain)

                            ForEach(ListingType.allCases) { type in
                                Button {
                                    selectType(type)
                                    quickFilter = nil
                                } label: {
                                    selectionRow(
                                        title: localizedTypeTitle(type),
                                        selected: viewModel.criteria.type
                                            == type
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollContentBackground(.hidden)
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
        }
    }

    private func selectionRow(title: String, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? Color.button : Color.title)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.button)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(selected ? Color.surfaceBackground : Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.button : Color.border, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    private func localizedTypeTitle(_ type: ListingType) -> String {
        switch type {
        case .stay: String(localized: "listing.type.stay")
        case .tour: String(localized: "listing.type.tour")
        case .activity: String(localized: "listing.type.activity")
        case .experience: String(localized: "listing.type.experience")
        }
    }
}

// MARK: - Row

struct SearchListingRow: View {
    @Environment(AppState.self) private var appState

    let listing: PublicListing
    let isFavorite: Bool
    let isUpdatingFavorite: Bool
    let canFavorite: Bool
    var usesProfileRoute = false
    let onFavorite: () -> Void

    private var currentRating: Rating? {
        appState.reviews.rating(for: listing.id, fallback: listing.rating)
    }

    var body: some View {
        HStack(spacing: 13) {
            Group {
                if usesProfileRoute {
                    NavigationLink(
                        value: ProfileDestination.listingDetails(listing)
                    ) {
                        listingSummary
                    }
                } else {
                    NavigationLink(value: AppRoute.listingDetails(listing)) {
                        listingSummary
                    }
                }
            }
            .buttonStyle(.plain)

            if canFavorite {
                Button(action: onFavorite) {
                    Group {
                        if isUpdatingFavorite {
                            ProgressView()
                        } else {
                            Image(
                                systemName: isFavorite ? "heart.fill" : "heart"
                            )
                        }
                    }
                    .foregroundStyle(
                        isFavorite ? Color.errorC : Color.description
                    )
                    .frame(width: 42, height: 42)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingFavorite)
            }
        }
        .padding(.vertical, 12)
        .foregroundStyle(Color.title)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.border).frame(height: 1)
        }
    }

    private var listingSummary: some View {
        HStack(spacing: 13) {
            thumbnail
            VStack(alignment: .leading, spacing: 5) {
                Text(listing.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                if let location = listing.location {
                    Label {
                        Text(
                            verbatim:
                                "\(location.city ?? ""), \(location.countryCode)"
                        )
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.description)
                    .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let category = listing.category {
                        Text(category.name).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Text(
                        listing.basePrice.formatted(
                            .number.precision(.fractionLength(0...2))
                        )
                            + " " + listing.currency
                    )
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(Color.description)

                if let rating = currentRating, let average = rating.average {
                    Label {
                        Text(
                            verbatim:
                                "\(average.formatted(.number.precision(.fractionLength(1)))) (\(rating.count))"
                        )
                    } icon: {
                        Image(systemName: "star.fill")
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.description)
                } else {
                    Text("provider.list.noReviews")
                        .font(.caption2)
                        .foregroundStyle(Color.description)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private var thumbnail: some View {
        Group {
            if let media = listing.coverMedia, media.type == .image,
                let url = URL(string: media.url)
            {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var placeholder: some View {
        Color.border.overlay {
            Image(systemName: "photo").foregroundStyle(Color.description)
        }
    }
}
