import Foundation

@MainActor
protocol FavoritesServicesProtocol {
    func getFavorites(limit: Int, page: Int, locale: String) async throws -> FavoritesPage
    func deleteFavorites(_ input: FavoriteRequest) async throws -> FavoriteResponse
}

enum NetworkError: Error { case invalidResponse }

@MainActor
final class FavoritesServices: FavoritesServicesProtocol {
    var calls: [Int] = []
    var fails = false
    var deleted = false
    func getFavorites(limit: Int, page: Int, locale: String) async throws -> FavoritesPage {
        precondition(limit == 2 && locale == "az")
        calls.append(page)
        if fails { throw NetworkError.invalidResponse }
        let ids = deleted ? ["b", "c"] : (page == 1 ? ["a", "b"] : ["b", "c"])
        return FavoritesPage(listings: ids.map(listing), meta: PaginationMeta(page: page, limit: 2, total: 3, totalPages: 2))
    }
    func deleteFavorites(_ input: FavoriteRequest) async throws -> FavoriteResponse {
        deleted = true
        return FavoriteResponse(isFavorite: false, favoritedAt: nil)
    }
}

func listing(_ id: String) -> ListingResponse {
    ListingResponse(id: id, title: id, slug: id, shortDescription: nil,
        description: "", basePrice: "10", currency: "AZN", isFeatured: false,
        category: nil, location: nil,
        media: UploadedFile(id: id, url: "https://example.com/image.jpg", originalName: "image", mimeType: "image/jpeg", sizeBytes: 1),
        amenities: [], rating: Rating(average: nil, count: 0), isFavorite: true, type: .stay, details: nil)
}

@main
struct Checks {
    @MainActor static func main() async throws {
        let service = FavoritesServices()
        let vm = FavoritesViewModel(service: service, limit: 2)
        await vm.load(locale: "az")
        precondition(vm.listings.map(\.id) == ["a", "b"])
        service.fails = true
        await vm.loadNextPage()
        guard case .error = vm.state else { fatalError("Expected loading failure") }
        precondition(vm.listings.count == 2)
        service.fails = false
        await vm.loadNextPage()
        guard case .loaded = vm.state else { fatalError("Expected loaded state after retry") }
        precondition(service.calls == [1, 2, 2])
        precondition(vm.listings.map(\.id) == ["a", "b", "c"] && !vm.hasMore)
        await vm.loadNextPage()
        precondition(service.calls.count == 3)
        await vm.remove(vm.listings[0])
        precondition(vm.listings.map(\.id) == ["b", "c"] && service.calls.last == 1)
        let decoded = try JSONDecoder().decode(FavoriteResponse.self, from: Data(#"{"isFavorite":false,"favoritedAt":null}"#.utf8))
        precondition(!decoded.isFavorite && decoded.favoritedAt == nil)
        // A refresh must supersede an old request, and duplicate loads must be ignored.
        let pagination = PaginationController<ListingResponse>(limit: 2)
        var pending: CheckedContinuation<PaginationPage<ListingResponse>, Never>?
        var requests = 0
        let oldLoad = Task { @MainActor in
            await pagination.refresh { _, _ in
                requests += 1
                return await withCheckedContinuation { pending = $0 }
            }
        }
        while pending == nil { await Task.yield() }
        await pagination.loadNextPage()
        precondition(requests == 1)
        await pagination.refresh { _, _ in
            PaginationPage(items: [listing("new")])
        }
        pending?.resume(returning: PaginationPage(items: [listing("old")], hasMore: true))
        await oldLoad.value
        precondition(pagination.items.map(\.id) == ["new"] && !pagination.hasMore)
        precondition(pagination.nextPage == 2)

        await pagination.refresh { _, _ in throw CancellationError() }
        guard case .idle = pagination.state else { fatalError("Cancellation should return to idle") }
        precondition(pagination.nextPage == 1 && pagination.items.isEmpty)
        await pagination.refresh { _, _ in PaginationPage(items: [], hasMore: true) }
        precondition(!pagination.hasMore)
        print("Generic pagination checks passed: concurrent loads, stale results, page-size fallback, cancellation, empty page.")
        print("Favorites checks passed: pagination, retry, deduplication, end of list, deletion refresh, nullable response.")
    }
}
