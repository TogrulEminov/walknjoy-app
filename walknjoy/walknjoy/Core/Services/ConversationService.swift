import Foundation

@MainActor final class ConversationService: ConversationServiceProtocol {
    var onSessionExpired: (() -> Void)?
    private let tokens: TokenStorageProtocol
    private let network: NetworkingService
    private let auth: AuthServiceProtocol
    private var refreshTask: Task<Void, Error>?
    init(
        network: NetworkingService? = nil,
        auth: AuthServiceProtocol? = nil,
        tokens: TokenStorageProtocol? = nil
    ) {
        self.tokens = tokens ?? TokenStorage()
        self.network = network ?? DefaultNetworkService()
        self.auth = auth ?? AuthService()
    }
    private func request<T: Decodable>(
        _ endpoint: ConversationEndpoint,
        type: T.Type
    ) async throws -> T {
        let originalToken = tokens.accessToken
        do {
            return try await network.request(
                enpoint: endpoint,
                responseType: type
            )
        } catch NetworkError.unauthorized {
            if tokens.accessToken == originalToken {
                if refreshTask == nil {
                    refreshTask = Task { try await auth.refresh() }
                }
                do {
                    try await refreshTask?.value
                    refreshTask = nil
                } catch {
                    refreshTask = nil
                    if tokens.accessToken == originalToken {
                        if Self.isSessionError(error) { onSessionExpired?() }
                        throw error
                    }
                }
            }
            do {
                return try await network.request(
                    enpoint: endpoint,
                    responseType: type
                )
            } catch NetworkError.unauthorized {
                onSessionExpired?()
                throw NetworkError.unauthorized
            }
        }
    }
    private static func isSessionError(_ error: Error) -> Bool {
        switch error {
        case NetworkError.unauthorized, NetworkError.invalidRefreshToken,
            NetworkError.tokenExpired:
            true
        default: false
        }
    }
    private func object<T: Decodable>(_ endpoint: ConversationEndpoint)
        async throws -> T
    {
        let value = try await request(endpoint, type: ApiResponse<T>.self)
        guard value.success, let data = value.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }
    func list(page: Int, locale: String) async throws -> ConversationPage {
        let value = try await request(
            .list(page: page, locale: locale),
            type: PaginatedResponse<ConversationRow>.self
        )
        guard value.success else { throw NetworkError.invalidResponse }
        return ConversationPage(items: value.data, meta: value.meta)
    }
    func detail(id: String, locale: String) async throws -> ConversationDetail {
        try await object(.detail(id, locale: locale))
    }
    func start(_ context: ConversationStart, locale: String) async throws
        -> ConversationDetail
    { try await object(.start(context, locale: locale)) }
    func messages(id: String, before: String?) async throws -> MessagePage {
        let result = try await request(
            .messages(id, before: before),
            type: MessagePage.self
        )
        guard result.success else { throw NetworkError.invalidResponse }
        return result
    }
    func send(id: String, content: String, clientMessageId: String) async throws
        -> ChatMessage
    {
        try await object(
            .send(id, content: content, clientMessageId: clientMessageId)
        )
    }
    func read(id: String, messageId: String) async throws -> ChatReadReceipt? {
        let result = try await request(
            .read(id, messageId: messageId),
            type: ChatReadResponse.self
        )
        guard result.success else { throw NetworkError.invalidResponse }
        return result.data
    }
}
