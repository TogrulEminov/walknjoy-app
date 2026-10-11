import Foundation

enum TravelPlannerEndpoint: Endpoint {
    case create(String)
    case get(String, String, Int)
    case answer(String, String, AnswerBody)
    case back(String, String, VersionBody)
    case reset(String, String, VersionBody)
    struct EmptyBody: Encodable {}
    struct VersionBody: Encodable { let version: Int }
    struct AnswerBody: Encodable { let version: Int; let step: String; let answer: PlannerAnswer }
    var path: String {
        switch self {
        case .create: return "/travel-planner/sessions"
        case .get(let id, _, _): return "/travel-planner/sessions/\(id)"
        case .answer(let id, _, _): return "/travel-planner/sessions/\(id)/answers"
        case .back(let id, _, _): return "/travel-planner/sessions/\(id)/back"
        case .reset(let id, _, _): return "/travel-planner/sessions/\(id)/reset"
        }
    }
    var baseURL: String {
        let base = APIConfig.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return base.hasSuffix("/api/v1") ? base : base + "/api/v1"
    }
    var method: HttpMethod { if case .get = self { return .get }; return .post }
    var requiresAuth: Bool { true }
    var headers: [String: String]? { [HttpHeader.accept: ContentType.applicationJson, HttpHeader.contentType: ContentType.applicationJson] }
    var queryItems: [URLQueryItem]? {
        let locale: String
        switch self {
        case .create(let l), .get(_, let l, _), .answer(_, let l, _), .back(_, let l, _), .reset(_, let l, _): locale = l
        }
        var items = [URLQueryItem(name: "locale", value: locale)]
        if case .get(_, _, let page) = self { items += [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: "10")] }
        return items
    }
    var httpBody: RequestBody {
        switch self {
        case .create: return .json(EmptyBody())
        case .get: return .none
        case .answer(_, _, let body): return .json(body)
        case .back(_, _, let body), .reset(_, _, let body): return .json(body)
        }
    }
}
