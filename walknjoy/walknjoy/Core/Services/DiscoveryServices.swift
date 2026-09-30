import Foundation

@MainActor
protocol DiscoveryServicesProtocol {
    func getPopularDestinations() async throws -> [PopularDestination]
    func getCities() async throws -> [ListingCity]
    func getCategories(type: ListingType?, locale: String) async throws -> [CategoryModel]
    func getAmenities(type: ListingType?, locale: String) async throws -> [AmenityModel]
}

@MainActor
final class DiscoveryServices: DiscoveryServicesProtocol {
    private let networkService: NetworkingService

    init(networkService: NetworkingService? = nil) {
        self.networkService = networkService ?? DefaultNetworkService()
    }

    func getCities() async throws -> [ListingCity] {
        let cities: [ListingCity] = try await data(for: ListingTaxonomyEndpoint.cities(locale: .az, countryCode: "AZ"))
        return cities.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func getPopularDestinations() async throws -> [PopularDestination] {
        try await data(for: DiscoveryEndpoint.popularDestinations)
    }

    func getCategories(type: ListingType?, locale: String) async throws -> [CategoryModel] {
        let categories: [CategoryModel] = try await data(for: CategoryEndpoint.filtered(type: type, locale: locale))
        return categories
            .filter { !$0.isDeleted }
            .sorted { $0.order < $1.order }
    }

    func getAmenities(type: ListingType?, locale: String) async throws -> [AmenityModel] {
        let amenities: [AmenityModel] = try await data(
            for: DiscoveryEndpoint.amenities(type: type, locale: locale)
        )
        return amenities.filter { !$0.isDeleted }
    }

    private func data<T: Decodable>(for endpoint: any Endpoint) async throws -> T {
        let response = try await networkService.request(
            enpoint: endpoint,
            responseType: ApiResponse<T>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }
}
