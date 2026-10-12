import Foundation

nonisolated protocol CategoryServicesProtocol {
    func getCategories() async throws -> [CategoryModel]
}

nonisolated final class CategoryServices: CategoryServicesProtocol {
    private let networkService: NetworkingService

    init(networkService: NetworkingService? = nil) {
        self.networkService = networkService ?? DefaultNetworkService()
    }

    func getCategories() async throws -> [CategoryModel] {
        let response = try await networkService.request(
            enpoint: CategoryEndpoint.getCategories,
            responseType: ApiResponse<[CategoryModel]>.self
        )

        guard let categories = response.data else {
            throw NetworkError.invalidResponse
        }

        return
            categories
            .filter { $0.isDeleted != true }
            .sorted { $0.order < $1.order }
    }
}
