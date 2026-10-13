import Foundation
import Observation

@MainActor
@Observable
final class FavoritesViewModel {
    private let service: FavoritesServicesProtocol
    let pagination: PaginationController<ListingResponse>
    private var locale: String?
    private(set) var removalState: LoadState<Void> = .idle
    private(set) var removingIDs: Set<String> = []

    var listings: [ListingResponse] { pagination.items.filter { !ListingLifecycle.shared.deletedIDs.contains($0.id) } }
    var nextPage: Int { pagination.nextPage }
    var hasMore: Bool { pagination.hasMore }
    var state: LoadState<Void> { pagination.state }
    var isLoading: Bool { pagination.isLoading }

    init(service: FavoritesServicesProtocol? = nil, limit: Int = 20) {
        self.service = service ?? FavoritesServices()
        self.pagination = PaginationController(limit: limit)
    }

    func load(locale: String) async {
        guard self.locale != locale || (listings.isEmpty && !isLoading) else {
            return
        }
        await refresh(locale: locale)
    }

    func refresh(locale: String) async {
        self.locale = locale
        let service = service
        await pagination.refresh { page, limit in
            let result = try await service.getFavorites(
                limit: limit,
                page: page,
                locale: locale
            )
            return PaginationPage(
                items: result.listings,
                hasMore: result.meta?.hasNextPage
            )
        }
    }

    func loadNextPage() async {
        await pagination.loadNextPage()
    }
    func invalidateDeletedListing(_ id: String) {
        pagination.remove(id: id)
    }

    func remove(_ listing: ListingResponse) async {
        guard removingIDs.insert(listing.id).inserted else { return }
        removalState = .loading
        defer { removingIDs.remove(listing.id) }
        do {
            let response = try await service.deleteFavorites(
                FavoriteRequest(listingId: listing.id)
            )
            guard !response.isFavorite else {
                throw NetworkError.invalidResponse
            }
            if removingIDs.count == 1 {
                switch removalState {
                case .error: break
                default: removalState = .loaded(())
                }
            }
            if let locale { await refresh(locale: locale) }
        } catch {
            removalState =
                error is CancellationError
                ? .idle : .error(error.localizedDescription)
        }
    }

    func dismissRemovalError() {
        removalState = removingIDs.isEmpty ? .idle : .loading
    }
}
