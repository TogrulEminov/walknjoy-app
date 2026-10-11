import Foundation

enum NotificationEndpoint: Endpoint {
    case list(unreadOnly: Bool, page: Int)
    case unreadCount
    case read(id: String)
    case readAll

    var path: String {
        switch self {
        case .list: "/notifications"
        case .unreadCount: "/notifications/unread-count"
        case .read(let id): "/notifications/\(id)/read"
        case .readAll: "/notifications/read-all"
        }
    }
    var method: HttpMethod {
        switch self {
        case .list, .unreadCount: .get
        case .read, .readAll: .post
        }
    }
    var requiresAuth: Bool { true }
    var queryItems: [URLQueryItem]? {
        guard case .list(let unreadOnly, let page) = self else { return nil }
        var items: [URLQueryItem] = []
        if unreadOnly {
            items.append(URLQueryItem(name: "unreadOnly", value: "true"))
        }
        if page > 1 {
            items.append(URLQueryItem(name: "page", value: String(page)))
        }
        return items
    }
}
