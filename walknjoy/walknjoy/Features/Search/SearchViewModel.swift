import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    static var makeDefault: (ListingSearchCriteria) -> SearchViewModel = {
        SearchViewModel(criteria: $0)
    }
    private let listingService: ListingServicesProtocol
    private let discoveryService: DiscoveryServicesProtocol
    private let favoritesService: FavoritesServicesProtocol
    private let pagination: PaginationController<PublicListing>

    var listings: [PublicListing] { pagination.items.filter { !ListingLifecycle.shared.deletedIDs.contains($0.id) } }
    var criteria: ListingSearchCriteria
    var paginationMeta: PaginationMeta? { pagination.meta }
    var destinations: [PopularDestination] = []
    var categories: [CategoryModel] = []
    var amenities: [AmenityModel] = []
    var isInitialLoading: Bool { pagination.isLoading && listings.isEmpty }
    var isLoadingNextPage: Bool { pagination.isLoading && !listings.isEmpty }
    var error: String?
    var favoriteOverrides: [String: Bool] = [:]
    var updatingFavoriteIDs: Set<String> = []
    private(set) var currentPage = 1

    var visibleListings: [PublicListing] {
        let pageSize = max(1, criteria.limit)
        let start = (currentPage - 1) * pageSize
        guard start < listings.count else { return [] }
        return Array(listings.dropFirst(start).prefix(pageSize))
    }

    var canGoToPreviousPage: Bool { currentPage > 1 }

    var canGoToNextPage: Bool {
        currentPage < loadedPageCount || pagination.hasMore
    }

    private var loadedPageCount: Int {
        max(
            1,
            (listings.count + max(1, criteria.limit) - 1)
                / max(1, criteria.limit)
        )
    }

    var hasMorePages: Bool {
        pagination.hasMore
    }

    init(
        criteria: ListingSearchCriteria,
        listingService: ListingServicesProtocol? = nil,
        discoveryService: DiscoveryServicesProtocol? = nil,
        favoritesService: FavoritesServicesProtocol? = nil
    ) {
        self.criteria = criteria
        self.pagination = PaginationController(limit: criteria.limit)
        self.listingService = listingService ?? ListingServices()
        self.discoveryService = discoveryService ?? DiscoveryServices()
        self.favoritesService = favoritesService ?? FavoritesServices()
    }

    func search() async {
        currentPage = 1
        criteria.page = 1
        error = nil
        let criteria = criteria
        let service = listingService
        await pagination.refresh { page, limit in
            var request = criteria
            request.page = page
            request.limit = limit
            let result = try await service.searchListings(criteria: request)
            return PaginationPage(items: result.listings, meta: result.meta)
        }
        if case .error(let message) = pagination.state { error = message }
    }

    func refresh() async { await search() }
    func invalidateDeletedListing(_ id: String) {
        pagination.remove(id: id)
        favoriteOverrides[id] = nil
        currentPage = min(currentPage, loadedPageCount)
    }

    func loadNextPageIfNeeded(currentItem: PublicListing) async {
        guard currentItem.id == listings.last?.id,
            hasMorePages, !isLoadingNextPage, !isInitialLoading
        else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingNextPage, !isInitialLoading else {
            return
        }
        error = nil
        let criteria = criteria
        let service = listingService
        await pagination.loadNextPage(using: { page, limit in
            var request = criteria
            request.page = page
            request.limit = limit
            let result = try await service.searchListings(criteria: request)
            return PaginationPage(items: result.listings, meta: result.meta)
        })
        if case .error(let message) = pagination.state { error = message }
    }

    func goToPreviousPage() {
        guard canGoToPreviousPage else { return }
        currentPage -= 1
    }

    func goToNextPage() async {
        guard canGoToNextPage, !isLoadingNextPage else { return }
        if currentPage < loadedPageCount {
            currentPage += 1
            return
        }

        let previousCount = listings.count
        await loadNextPage()
        if listings.count > previousCount {
            currentPage += 1
        }
    }

    func applyFilters(_ updated: ListingSearchCriteria) async {
        criteria = updated
        criteria.page = 1
        await loadAmenities()
        await search()
    }

    func resetFilters() async {
        criteria.resetFilters()
        await loadAmenities()
        await search()
    }

    func loadDiscovery() async {
        async let destinationsRequest =
            discoveryService.getPopularDestinations()
        async let categoriesRequest = discoveryService.getCategories(
            type: criteria.type,
            locale: criteria.locale
        )
        async let amenitiesRequest = discoveryService.getAmenities(
            type: criteria.type,
            locale: criteria.locale
        )
        do {
            (destinations, categories, amenities) = try await (
                destinationsRequest, categoriesRequest, amenitiesRequest
            )
        } catch is CancellationError {
            return
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAmenities() async {
        do {
            async let categoriesRequest = discoveryService.getCategories(
                type: criteria.type,
                locale: criteria.locale
            )
            async let amenitiesRequest = discoveryService.getAmenities(
                type: criteria.type,
                locale: criteria.locale
            )
            (categories, amenities) = try await (
                categoriesRequest, amenitiesRequest
            )
        } catch is CancellationError {
            return
        } catch {
            self.error = error.localizedDescription
        }
    }

    func isFavorite(_ listing: PublicListing) -> Bool {
        favoriteOverrides[listing.id] ?? listing.isFavorite
    }

    func toggleFavorite(for listing: PublicListing) async {
        guard updatingFavoriteIDs.insert(listing.id).inserted else { return }
        defer { updatingFavoriteIDs.remove(listing.id) }
        do {
            let response =
                isFavorite(listing)
                ? try await favoritesService.deleteFavorites(
                    FavoriteRequest(listingId: listing.id)
                )
                : try await favoritesService.addFavorites(
                    FavoriteRequest(listingId: listing.id)
                )
            favoriteOverrides[listing.id] = response.isFavorite
        } catch {
            self.error = error.localizedDescription
        }
    }
}
