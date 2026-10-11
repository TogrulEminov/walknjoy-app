import Foundation

@MainActor
protocol TravelPlannerServiceProtocol {
    func request(_ endpoint: TravelPlannerEndpoint) async throws -> PlannerSession
}
@MainActor
final class TravelPlannerService: TravelPlannerServiceProtocol {
    private let network: NetworkingService
    private let auth: AuthServiceProtocol
    init(network: NetworkingService? = nil, auth: AuthServiceProtocol? = nil) {
        self.auth = auth ?? AuthService()
        self.network = network ?? DefaultNetworkService()
    }
    func request(_ endpoint: TravelPlannerEndpoint) async throws -> PlannerSession {
        do { return try await fetch(endpoint) }
        catch let failure as APIRequestFailure where failure.error.code == "UNAUTHORIZED" || failure.error.code == "TOKEN_EXPIRED" {
            try await auth.refresh()
            return try await fetch(endpoint)
        } catch NetworkError.unauthorized {
            try await auth.refresh()
            return try await fetch(endpoint)
        }
    }
    private func fetch(_ endpoint: TravelPlannerEndpoint) async throws -> PlannerSession {
        let response = try await network.request(enpoint: endpoint, responseType: ApiResponse<PlannerSession>.self)
        guard response.success, let data = response.data else { throw NetworkError.invalidResponse }
        return data
    }
}
