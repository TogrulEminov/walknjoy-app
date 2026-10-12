import Foundation

nonisolated protocol FavoritesServicesProtocol {
    func addFavorites(_ input: FavoriteRequest) async throws -> FavoriteResponse
    func deleteFavorites(_ input: FavoriteRequest) async throws
        -> FavoriteResponse
    func getFavorites(limit: Int, page: Int, locale: String) async throws
        -> FavoritesPage
}

nonisolated final class FavoritesServices: FavoritesServicesProtocol {
    private let networkService: NetworkingService

    init(networkService: NetworkingService? = nil) {
        self.networkService = networkService ?? DefaultNetworkService()
    }

    func addFavorites(_ input: FavoriteRequest) async throws -> FavoriteResponse
    {
        try await update(.addFavorites(input.listingId))
    }

    func deleteFavorites(_ input: FavoriteRequest) async throws
        -> FavoriteResponse
    {
        try await update(.deleteFavorites(input.listingId))
    }

    private func update(_ endpoint: FavoritesEndpoint) async throws
        -> FavoriteResponse
    {
        let response = try await networkService.request(
            enpoint: endpoint,
            responseType: ApiResponse<FavoriteResponse>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func getFavorites(limit: Int, page: Int, locale: String) async throws
        -> FavoritesPage
    {
        let response = try await networkService.request(
            enpoint: FavoritesEndpoint.getFavorites(
                limit: limit,
                page: page,
                locale: locale
            ),
            responseType: ApiResponse<[ListingResponse]>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return FavoritesPage(listings: data, meta: response.meta)
    }
}
