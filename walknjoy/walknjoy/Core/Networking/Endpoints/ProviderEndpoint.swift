import Foundation

enum ProviderEndpoint {
    case apply(ProviderApplicationInput)
    case getProfile
    case updateProfile(UpdateProviderProfileInput)
}
extension ProviderEndpoint: Endpoint {
    var path: String {
        switch self {
        case .apply: "/providers/apply"
        case .getProfile, .updateProfile: "/providers/me"
        }
    }

    var method: HttpMethod {
        switch self {
        case .apply: .post
        case .getProfile: .get
        case .updateProfile: .patch
        }
    }

    var queryItems: [URLQueryItem]? { nil }

    var httpBody: RequestBody {
        switch self {
        case .apply(let input): .json(input)
        case .getProfile: .none
        case .updateProfile(let input): .json(input)
        }
    }

    var requiresAuth: Bool { true }
}
