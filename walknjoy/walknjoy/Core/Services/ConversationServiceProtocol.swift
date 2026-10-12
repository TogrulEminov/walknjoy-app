import Foundation

@MainActor
protocol ConversationServiceProtocol {
    func list(page: Int, locale: String) async throws -> ConversationPage
    func detail(id: String, locale: String) async throws -> ConversationDetail
    func start(_ context: ConversationStart, locale: String) async throws
        -> ConversationDetail
    func messages(id: String, before: String?) async throws -> MessagePage
    func send(id: String, content: String, clientMessageId: String) async throws
        -> ChatMessage
    func read(id: String, messageId: String) async throws -> ChatReadReceipt?
}
