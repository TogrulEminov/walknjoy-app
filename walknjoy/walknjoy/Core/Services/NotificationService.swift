import Foundation

nonisolated struct NotificationPage {
    let items: [AppNotification]
    let meta: PaginationMeta?
}

nonisolated protocol NotificationServiceProtocol {
    func list(unreadOnly: Bool, page: Int) async throws -> NotificationPage
    func unreadCount() async throws -> Int
    func markRead(id: String) async throws
    func markAllRead() async throws
}

nonisolated final class NotificationService: NotificationServiceProtocol {
    private let network: NetworkingService
    init(network: NetworkingService? = nil) {
        self.network = network ?? DefaultNetworkService()
    }

    func list(unreadOnly: Bool = false, page: Int = 1) async throws
        -> NotificationPage
    {
        let response = try await network.request(
            enpoint: NotificationEndpoint.list(
                unreadOnly: unreadOnly,
                page: page
            ),
            responseType: ApiResponse<[AppNotification]>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return NotificationPage(items: data, meta: response.meta)
    }
    func unreadCount() async throws -> Int {
        let response = try await network.request(
            enpoint: NotificationEndpoint.unreadCount,
            responseType: ApiResponse<NotificationUnreadCount>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return max(0, data.count)
    }
    func markRead(id: String) async throws {
        guard NotificationData.isSafeIdentifier(id) else {
            throw NetworkError.invalidResponse
        }
        let response = try await network.request(
            enpoint: NotificationEndpoint.read(id: id),
            responseType: ApiResponse<AppNotification>.self
        )
        guard response.success, let data = response.data, data.id == id,
            data.isRead
        else { throw NetworkError.invalidResponse }
    }
    func markAllRead() async throws {
        let response = try await network.request(
            enpoint: NotificationEndpoint.readAll,
            responseType: ApiResponse<NotificationReadAllResult>.self
        )
        guard response.success, let data = response.data, data.updatedCount >= 0
        else { throw NetworkError.invalidResponse }
    }
}

private nonisolated struct NotificationReadAllResult: Decodable {
    let updatedCount: Int
}

nonisolated struct NotificationUnreadCount: Decodable {
    let count: Int
}

extension Error {
    var isNotificationAuthenticationError: Bool {
        guard let error = self as? NetworkError else { return false }
        switch error {
        case .unauthorized, .tokenExpired, .invalidRefreshToken: return true
        case .serverError(let status): return status == 401
        default: return false
        }
    }
}
