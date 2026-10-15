import Foundation

nonisolated enum DiscoveryEndpoint: Endpoint {
    case popularDestinations
    case amenities(type: ListingType?, locale: String)

    var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringLocalCacheData }

    var path: String {
        switch self {
        case .popularDestinations: "/discovery/popular-destinations"
        case .amenities: "/amenities"
        }
    }

    var method: HttpMethod { .get }

    var queryItems: [URLQueryItem]? {
        var items = [URLQueryItem(name: "locale", value: "az")]
        if case .amenities(let type, let locale) = self {
            items = [URLQueryItem(name: "locale", value: locale)]
            if let type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
        }
        return items
    }
}
