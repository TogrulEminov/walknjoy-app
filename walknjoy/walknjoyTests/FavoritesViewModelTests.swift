import Foundation
import Testing

@testable import walknjoy

@MainActor
struct FavoritesViewModelTests {
    @Test func loadSuccessDisplaysFavoritesAndPassesRequestParameters() async {
        let service = MockFavoritesService()
        let viewModel = FavoritesViewModel(service: service, limit: 2)

        await viewModel.load(locale: "az")

        guard case .loaded = viewModel.state else {
            Issue.record("Expected loaded favorites")
            return
        }
        #expect(viewModel.listings.map(\.id) == ["listing-1", "listing-2"])
        #expect(service.requests.count == 1)
        #expect(service.requests.first?.page == 1)
        #expect(service.requests.first?.limit == 2)
        #expect(service.requests.first?.locale == "az")
        #expect(viewModel.nextPage == 2)
        #expect(viewModel.hasMore)
        #expect(!viewModel.isLoading)
    }

    @Test func loadFailureShowsErrorAndCanRetry() async {
        let service = MockFavoritesService()
        service.loadError = FavoritesTestError.failed
        let viewModel = FavoritesViewModel(service: service, limit: 2)

        await viewModel.load(locale: "az")

        guard case .error(let message) = viewModel.state else {
            Issue.record("Expected load error")
            return
        }
        #expect(message == FavoritesTestError.failed.localizedDescription)
        #expect(viewModel.listings.isEmpty)
        #expect(!viewModel.isLoading)

        service.loadError = nil
        await viewModel.load(locale: "az")

        #expect(viewModel.listings.count == 2)
        #expect(service.requests.map(\.page) == [1, 1])
    }

    @Test func sameLocaleDoesNotReloadButNewLocaleRefreshes() async {
        let service = MockFavoritesService()
        let viewModel = FavoritesViewModel(service: service, limit: 2)
        await viewModel.load(locale: "az")

        await viewModel.load(locale: "az")
        #expect(service.requests.count == 1)

        await viewModel.load(locale: "en")
        #expect(service.requests.map(\.locale) == ["az", "en"])
        #expect(service.requests.map(\.page) == [1, 1])
        #expect(viewModel.listings.count == 2)
    }

    @Test func nextPageAppendsFavoritesAndStopsAtLastPage() async {
        let service = MockFavoritesService()
        let viewModel = FavoritesViewModel(service: service, limit: 2)
        await viewModel.load(locale: "az")

        await viewModel.loadNextPage()

        #expect(
            viewModel.listings.map(\.id) == [
                "listing-1", "listing-2", "listing-3",
            ]
        )
        #expect(service.requests.map(\.page) == [1, 2])
        #expect(viewModel.nextPage == 3)
        #expect(!viewModel.hasMore)

        await viewModel.loadNextPage()
        #expect(service.requests.count == 2)
    }

    @Test func removeSuccessSendsListingIDAndRefreshesFavorites() async throws {
        let service = MockFavoritesService()
        let viewModel = FavoritesViewModel(service: service, limit: 2)
        await viewModel.load(locale: "az")
        let listing = try #require(viewModel.listings.first)

        await viewModel.remove(listing)

        #expect(service.deletedIDs == [listing.id])
        #expect(service.requests.map(\.page) == [1, 1])
        #expect(viewModel.listings.map(\.id) == ["listing-2"])
        #expect(viewModel.removingIDs.isEmpty)
        guard case .loaded = viewModel.removalState else {
            Issue.record("Expected successful removal")
            return
        }
    }

    @Test func removeFailureKeepsFavoritesAndCanDismissError() async throws {
        let service = MockFavoritesService()
        let viewModel = FavoritesViewModel(service: service, limit: 2)
        await viewModel.load(locale: "az")
        let listing = try #require(viewModel.listings.first)
        service.deleteError = FavoritesTestError.failed

        await viewModel.remove(listing)

        guard case .error(let message) = viewModel.removalState else {
            Issue.record("Expected removal error")
            return
        }
        #expect(message == FavoritesTestError.failed.localizedDescription)
        #expect(viewModel.listings.map(\.id) == ["listing-1", "listing-2"])
        #expect(service.deletedIDs == [listing.id])
        #expect(service.requests.count == 1)
        #expect(viewModel.removingIDs.isEmpty)

        viewModel.dismissRemovalError()
        guard case .idle = viewModel.removalState else {
            Issue.record("Expected dismissed error")
            return
        }
    }

    @Test func removeRejectsResponseThatStillMarksListingAsFavorite()
        async throws
    {
        let service = MockFavoritesService()
        let viewModel = FavoritesViewModel(service: service, limit: 2)
        await viewModel.load(locale: "az")
        let listing = try #require(viewModel.listings.first)
        service.deleteResponse = FavoriteResponse(
            isFavorite: true,
            favoritedAt: nil
        )

        await viewModel.remove(listing)

        guard case .error(let message) = viewModel.removalState else {
            Issue.record("Expected invalid response error")
            return
        }
        #expect(message == NetworkError.invalidResponse.localizedDescription)
        #expect(viewModel.listings.count == 2)
        #expect(service.requests.count == 1)
        #expect(viewModel.removingIDs.isEmpty)
    }
}
private nonisolated final class MockFavoritesService: FavoritesServicesProtocol
{
    struct Request {
        let limit: Int
        let page: Int
        let locale: String
    }

    var requests: [Request] = []
    var deletedIDs: [String] = []
    var loadError: FavoritesTestError?
    var deleteError: FavoritesTestError?
    var deleteResponse = FavoriteResponse(isFavorite: false, favoritedAt: nil)
    private var removedIDs: Set<String> = []

    func getFavorites(limit: Int, page: Int, locale: String) async throws
        -> FavoritesPage
    {
        requests.append(Request(limit: limit, page: page, locale: locale))
        if let loadError { throw loadError }
        let ids = page == 1 ? ["listing-1", "listing-2"] : ["listing-3"]
        let listings = ids.filter { !removedIDs.contains($0) }.map {
            PublicListing(
                id: $0,
                type: .experience,
                title: "Favorite \($0)",
                slug: $0,
                basePrice: 25,
                currency: "AZN",
                isFavorite: true
            )
        }
        return FavoritesPage(
            listings: listings,
            meta: PaginationMeta(
                page: page,
                limit: limit,
                total: 3,
                totalPages: 2
            )
        )
    }

    func deleteFavorites(_ input: FavoriteRequest) async throws
        -> FavoriteResponse
    {
        deletedIDs.append(input.listingId)
        if let deleteError { throw deleteError }
        if !deleteResponse.isFavorite { removedIDs.insert(input.listingId) }
        return deleteResponse
    }

    func addFavorites(_ input: FavoriteRequest) async throws -> FavoriteResponse
    {
        Issue.record("Unexpected addFavorites call")
        throw FavoritesTestError.failed
    }
}

private nonisolated enum FavoritesTestError: LocalizedError {
    case failed
    var errorDescription: String? { "Mock favorites service failed" }
}
