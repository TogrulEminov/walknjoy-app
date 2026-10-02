import Foundation

@MainActor
protocol AIServicesProtocol {
    func suggestions(locale: String, limit: Int) async throws -> AISuggestions
    func conversations(page: Int, limit: Int) async throws
        -> [AIConversationSummary]
    func createConversation(title: String?) async throws -> AIConversation
    func conversation(id: String, page: Int, limit: Int, locale: String)
        async throws -> AIConversation
    func messages(id: String, page: Int, limit: Int, locale: String)
        async throws -> [AIMessage]
    func sendMessage(id: String, locale: String, input: AISendMessage)
        async throws -> AISentMessages
    func deleteConversation(id: String) async throws
}

@MainActor
final class AIServices: AIServicesProtocol {
    private let network: NetworkingService

    init(network: NetworkingService? = nil) {
        self.network = network ?? DefaultNetworkService()
    }

    func suggestions(locale: String, limit: Int = 10) async throws
        -> AISuggestions
    {
        try await data(
            for: .suggestions(locale: locale, limit: limit, type: nil)
        )
    }

    func conversations(page: Int, limit: Int) async throws
        -> [AIConversationSummary]
    {
        try await data(for: .conversations(page: page, limit: limit))
    }

    func createConversation(title: String?) async throws -> AIConversation {
        try await data(
            for: .createConversation(AICreateConversation(title: title))
        )
    }

    func conversation(
        id: String,
        page: Int,
        limit: Int,
        locale: String
    ) async throws -> AIConversation {
        try await data(
            for: .conversation(id: id, page: page, limit: limit, locale: locale)
        )
    }

    func messages(
        id: String,
        page: Int,
        limit: Int,
        locale: String
    ) async throws -> [AIMessage] {
        try await data(
            for: .messages(id: id, page: page, limit: limit, locale: locale)
        )
    }

    func sendMessage(
        id: String,
        locale: String,
        input: AISendMessage
    ) async throws -> AISentMessages {
        try await data(for: .sendMessage(id: id, locale: locale, input: input))
    }

    func deleteConversation(id: String) async throws {
        let _: AIDeletedConversation = try await data(
            for: .deleteConversation(id: id)
        )
    }

    private func data<T: Decodable>(for endpoint: AIEndpoint) async throws -> T
    {
        let response = try await network.request(
            enpoint: endpoint,
            responseType: ApiResponse<T>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }
}
