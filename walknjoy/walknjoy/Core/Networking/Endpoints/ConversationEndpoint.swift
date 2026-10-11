import Foundation

enum ConversationEndpoint {
    case list(page: Int, locale: String)
    case detail(String, locale: String)
    case start(ConversationStart, locale: String)
    case messages(String, before: String?)
    case send(String, content: String, clientMessageId: String)
    case read(String, messageId: String)
}

struct StartBody: Encodable {
    let listingId: String?
    let bookingId: String?
}
struct SendBody: Encodable {
    let content: String
    let clientMessageId: String
}

extension ConversationEndpoint: Endpoint {

    struct ReadBody: Encodable { let messageId: String }
    var path: String {
        switch self {
        case .list, .start(.listing, _), .start(.booking, _): "/conversations"
        case .start(.providerBooking(let id), _):
            "/provider/bookings/\(escaped(id))/conversation"
        case .detail(let id, _): "/conversations/\(escaped(id))"
        case .messages(let id, _), .send(let id, _, _):
            "/conversations/\(escaped(id))/messages"
        case .read(let id, _): "/conversations/\(escaped(id))/read"
        }
    }
    private func escaped(_ value: String) -> String {
        value.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed.subtracting(
                CharacterSet(charactersIn: "/?#%")
            )
        ) ?? value
    }
    var requiresAuth: Bool { true }
    var method: HttpMethod {
        switch self {
        case .list, .detail, .messages: .get
        default: .post
        }
    }
    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let page, let locale):
            makeQueryItems(["page": page, "limit": 20, "locale": locale])
        case .detail(_, let locale), .start(_, let locale):
            makeQueryItems(["locale": locale])
        case .messages(_, let cursor):
            makeQueryItems(["limit": 30, "before": cursor])
        default: nil
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .start(.listing(let id), _):
            .json(StartBody(listingId: id, bookingId: nil))
        case .start(.booking(let id), _):
            .json(StartBody(listingId: nil, bookingId: id))
        case .send(_, let content, let id):
            .json(SendBody(content: content, clientMessageId: id))
        case .read(_, let id): .json(ReadBody(messageId: id))
        default: .none
        }
    }
}
