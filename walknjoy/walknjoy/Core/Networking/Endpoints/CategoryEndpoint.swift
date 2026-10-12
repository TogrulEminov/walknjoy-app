import Foundation

nonisolated enum CategoryEndpoint: Endpoint {
    case getCategories
    case filtered(type: ListingType?, locale: String)

    var path: String {
        "/categories"
    }

    var method: HttpMethod {
        .get
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getCategories: return [URLQueryItem(name: "locale", value: "az")]
        case .filtered(let type, let locale):
            var items = [URLQueryItem(name: "locale", value: locale)]
            if let type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
            return items
        }
    }
}
