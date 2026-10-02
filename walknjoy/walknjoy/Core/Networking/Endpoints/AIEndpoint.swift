import Foundation

enum AIEndpoint {
    case suggestions(locale: String, limit: Int, type: ListingType?)
    case conversations(page: Int, limit: Int)
    case createConversation(AICreateConversation)
    case conversation(id: String, page: Int, limit: Int, locale: String)
    case messages(id: String, page: Int, limit: Int, locale: String)
    case sendMessage(id: String, locale: String, input: AISendMessage)
    case deleteConversation(id: String)
}
extension AIEndpoint: Endpoint {
    var path: String {
        switch self {
        case .suggestions: "/ai/suggestions"
        case .conversations, .createConversation: "/ai/conversations"
        case .conversation(let id, _, _, _), .deleteConversation(let id):
            "/ai/conversations/\(id)"
        case .messages(let id, _, _, _), .sendMessage(let id, _, _):
            "/ai/conversations/\(id)/messages"
        }
    }

    var method: HttpMethod {
        switch self {
        case .createConversation: .post
        case .sendMessage: .post
        case .deleteConversation: .delete
        case .suggestions, .conversations, .conversation, .messages: .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .suggestions(let locale, let limit, let type):
            var items = [
                URLQueryItem(name: "locale", value: locale),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
            if let type {
                items.append(
                    URLQueryItem(
                        name: "type",
                        value: type.rawValue.uppercased()
                    )
                )
            }
            return items
        case .conversations(let page, let limit):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        case .conversation(_, let page, let limit, let locale),
            .messages(_, let page, let limit, let locale):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "locale", value: locale),
            ]
        case .sendMessage(_, let locale, _):
            return [URLQueryItem(name: "locale", value: locale)]
        case .createConversation, .deleteConversation:
            return nil
        }
    }

    var httpBody: RequestBody {
        switch self {
        case .createConversation(let input): .json(input)
        case .sendMessage(_, _, let input): .json(input)
        default: .none
        }
    }

    var requiresAuth: Bool {
        if case .suggestions = self { return false }
        return true
    }
}
