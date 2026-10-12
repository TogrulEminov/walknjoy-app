import Foundation

nonisolated enum ProviderListingEndpoint: Endpoint {
    case list(ProviderListingsQuery)
    case get(id: String)
    case create(CreateListingRequest)
    case update(id: String, input: UpdateListingRequest)
    case updatePrice(id: String, input: ProviderPriceUpdateRequest)
    case getDetails(id: String)
    case details(id: String, input: ListingDetailsInput)
    case submit(id: String)
    case archive(id: String)
    case addMedia(id: String, input: ProviderMediaRequest)
    case deleteMedia(id: String, mediaId: String)

    var path: String {
        switch self {
        case .list, .create: "/provider/listings"
        case .get(let id), .update(let id, _), .updatePrice(let id, _),
            .archive(let id):
            "/provider/listings/\(id)"
        case .getDetails(let id), .details(let id, _):
            "/provider/listings/\(id)/details"
        case .addMedia(let id, _): "/provider/listings/\(id)/media"
        case .deleteMedia(let id, let mediaId):
            "/provider/listings/\(id)/media/\(mediaId)"
        case .submit(let id): "/provider/listings/\(id)/submit"
        }
    }
    var method: HttpMethod {
        switch self {
        case .list, .get, .getDetails: .get
        case .create, .submit, .addMedia: .post
        case .archive, .deleteMedia: .delete
        case .update, .updatePrice: .patch
        case .details: .put
        }
    }
    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let query): query.queryItems()
        default: nil
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .create(let input): .json(input)
        case .update(_, let input): .json(input)
        case .updatePrice(_, let input): .json(input)
        case .details(_, let input): .json(input)
        case .addMedia(_, let input): .json(input)
        default: .none
        }
    }
    var requiresAuth: Bool { true }
}

nonisolated enum ListingTaxonomyEndpoint: Endpoint {
    case cities(locale: ListingLocale, countryCode: String)
    case categories(type: ListingType, locale: ListingLocale)
    case amenities(type: ListingType, locale: ListingLocale)
    var path: String {
        switch self {
        case .cities: "/cities"
        case .categories: "/categories"
        case .amenities: "/amenities"
        }
    }
    var method: HttpMethod { .get }
    var queryItems: [URLQueryItem]? {
        switch self {
        case .cities(let locale, let countryCode):
            [
                URLQueryItem(name: "locale", value: locale.rawValue),
                URLQueryItem(name: "countryCode", value: countryCode),
            ]
        case .categories(let type, let locale),
            .amenities(let type, let locale):
            [
                URLQueryItem(name: "type", value: type.rawValue),
                URLQueryItem(name: "locale", value: locale.rawValue),
            ]
        }
    }
}
