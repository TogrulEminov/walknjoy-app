import Foundation

@MainActor
protocol ProviderServiceProtocol {
    func getProfile() async throws -> ProviderProfile
    func apply(_ input: ProviderApplicationInput) async throws
        -> ProviderProfile
    func updateProfile(_ input: UpdateProviderProfileInput) async throws
        -> ProviderProfile
}

@MainActor
final class ProviderService: ProviderServiceProtocol {
    private let networkService: NetworkingService
    private let tokenStorage: TokenStorageProtocol

    init(
        networkService: NetworkingService? = nil,
        tokenStorage: TokenStorageProtocol? = nil
    ) {
        self.networkService = networkService ?? DefaultNetworkService()
        self.tokenStorage = tokenStorage ?? TokenStorage()
    }

    func getProfile() async throws -> ProviderProfile {
        try await request(.getProfile)
    }

    func apply(_ input: ProviderApplicationInput) async throws
        -> ProviderProfile
    {
        let response = try await networkService.request(
            enpoint: ProviderEndpoint.apply(input),
            responseType: ApiResponse<ProviderApplicationResponseData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        try tokenStorage.updateAccessToken(data.accessToken)
        return data.profile
    }

    func updateProfile(_ input: UpdateProviderProfileInput) async throws
        -> ProviderProfile
    {
        try await request(.updateProfile(input))
    }

    private func request(_ endpoint: ProviderEndpoint) async throws
        -> ProviderProfile
    {
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
