import Foundation

nonisolated enum ReviewEndpoint: Endpoint {
    case listing(
        slug: String,
        page: Int,
        limit: Int,
        sort: ReviewSort,
        locale: String
    )
    case create(bookingID: String, request: CreateReviewRequest)
    case mine(page: Int, limit: Int)
    case update(id: String, request: UpdateReviewRequest)
    case delete(id: String)

    var path: String {
        switch self {
        case .listing(let slug, _, _, _, _):
            "/listings/\(Self.segment(slug))/reviews"
        case .create(let id, _): "/bookings/\(Self.segment(id))/review"
        case .mine: "/profile/reviews"
        case .update(let id, _), .delete(let id): "/reviews/\(Self.segment(id))"
        }
    }
    var method: HttpMethod {
        switch self {
        case .listing, .mine: .get
        case .create: .post
        case .update: .patch
        case .delete: .delete
        }
    }
    var requiresAuth: Bool { if case .listing = self { false } else { true } }
    var queryItems: [URLQueryItem]? {
        switch self {
        case .listing(_, let page, let limit, let sort, let locale):
            [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "locale", value: locale),
            ]
        case .mine(let page, let limit):
            [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "sort", value: "newest"),
                URLQueryItem(name: "locale", value: UserDefaultsService().selectedLanguage.rawValue),
            ]
        default: nil
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .create(_, let request): .json(request)
        case .update(_, let request): .json(request)
        default: .none
        }
    }
    private static func segment(_ value: String) -> String {
        value.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed.subtracting(
                CharacterSet(charactersIn: "/?#%")
            )
        ) ?? value
    }
}
