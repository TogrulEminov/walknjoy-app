import Foundation

@MainActor
protocol ProviderServiceProtocol {
    func getProfile() async throws -> ProviderProfile
    func apply(_ input: ProviderApplicationInput) async throws -> ProviderProfile
    func updateProfile(_ input: UpdateProviderProfileInput) async throws -> ProviderProfile
}

@MainActor
final class ProviderService: ProviderServiceProtocol {
    private let networkService: NetworkingService

    init(networkService: NetworkingService? = nil) {
        self.networkService = networkService ?? DefaultNetworkService()
    }

    func getProfile() async throws -> ProviderProfile {
        try await request(.getProfile)
    }

    func apply(_ input: ProviderApplicationInput) async throws -> ProviderProfile {
        try await request(.apply(input))
    }

    func updateProfile(_ input: UpdateProviderProfileInput) async throws -> ProviderProfile {
        try await request(.updateProfile(input))
    }

    private func request(_ endpoint: ProviderEndpoint) async throws -> ProviderProfile {
        let response = try await networkService.request(
            enpoint: endpoint,
            responseType: ApiResponse<ProviderProfile>.self
        )
        guard response.success, let profile = response.data else {
            throw NetworkError.invalidResponse
        }
        return profile
    }
}
