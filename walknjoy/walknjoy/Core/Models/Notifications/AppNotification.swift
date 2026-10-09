import Foundation

struct AppNotification: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let title: String
    let body: String
    let data: NotificationData?
    var isRead: Bool
    let createdAt: String
}

struct NotificationData: Codable, Hashable {
    var route: String?
    var bookingId: String?
    var listingId: String?
    var listingSlug: String?

    var validatedListingSlug: String? {
        if let route, !["listing", "listing_detail"].contains(route) {
            return nil
        }
        guard let listingSlug, Self.isSafeIdentifier(listingSlug) else { return nil }
        return listingSlug
    }

    static func isSafeIdentifier(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.count <= 128 && value.unicodeScalars.allSatisfy {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_").contains($0)
        }
    }
}

struct WebSocketEvent<T: Codable>: Codable {
    let event: String
    let data: T
}

enum NotificationEventDecoder {
    private struct Header: Decodable { let event: String }
    static func notification(from data: Data) throws -> AppNotification? {
        let decoder = JSONDecoder()
        guard try decoder.decode(Header.self, from: data).event == "notification:new" else { return nil }
        let value = try decoder.decode(WebSocketEvent<AppNotification>.self, from: data).data
        guard NotificationData.isSafeIdentifier(value.id) else { return nil }
        return value
    }
}
