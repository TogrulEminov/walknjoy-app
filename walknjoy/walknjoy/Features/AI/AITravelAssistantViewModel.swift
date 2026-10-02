import Foundation
import Observation

@MainActor
@Observable
final class AITravelAssistantViewModel {
    private(set) var suggestions: [AISuggestion] = []
    private(set) var conversations: [AIConversationSummary] = []
    private(set) var messages: [AIMessage] = []
    private(set) var conversationId: String?
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var errorMessage: String?
    private(set) var retryMessage: String?
    private var pendingUserMessageID: String?

    private let service: AIServicesProtocol

    init(service: AIServicesProtocol? = nil) {
        self.service = service ?? AIServices()
    }

    func load(locale: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let suggestionsRequest = service.suggestions(
                locale: locale,
                limit: 10
            )
            async let conversationsRequest = service.conversations(
                page: 1,
                limit: 30
            )
            let loadedSuggestions = try await suggestionsRequest
            let loadedConversations = try await conversationsRequest
            suggestions =
                loadedSuggestions.suggestions + loadedSuggestions.general
            conversations = loadedConversations
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openConversation(_ id: String, locale: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await service.conversation(
                id: id,
                page: 1,
                limit: 50,
                locale: locale
            )
            conversationId = result.id
            messages = result.messages.sorted { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startNewConversation() {
        conversationId = nil
        messages = []
        errorMessage = nil
        retryMessage = nil
        pendingUserMessageID = nil
    }

    func dismissError() {
        errorMessage = nil
    }

    func send(_ text: String, locale: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        isSending = true
        errorMessage = nil
        retryMessage = nil
        defer { isSending = false }

        let optimisticMessage: AIMessage
        if let pendingUserMessageID,
            let existingMessage = messages.first(where: { $0.id == pendingUserMessageID })
        {
            optimisticMessage = existingMessage
        } else {
            optimisticMessage = AIMessage(
                id: UUID().uuidString,
                role: .user,
                content: trimmed,
                createdAt: .now
            )
            pendingUserMessageID = optimisticMessage.id
            messages.append(optimisticMessage)
        }

        do {
            let id: String
            if let conversationId {
                id = conversationId
            } else {
                let conversation = try await service.createConversation(
                    title: nil
                )
                id = conversation.id
                conversationId = id
            }
            let result = try await service.sendMessage(
                id: id,
                locale: locale,
                input: AISendMessage(message: trimmed, context: nil)
            )
            messages.removeAll { $0.id == optimisticMessage.id }
            messages.append(contentsOf: [result.userMessage, result.assistantMessage])
            messages.sort { $0.createdAt < $1.createdAt }
            pendingUserMessageID = nil
            await refreshConversations()
        } catch {
            retryMessage = trimmed
            errorMessage = error.localizedDescription
            if let conversationId {
                await reloadMessages(id: conversationId, locale: locale)
            }
        }
    }

    func retry(locale: String) async {
        guard let retryMessage else { return }
        await send(retryMessage, locale: locale)
    }

    func deleteConversation(_ id: String) async {
        do {
            try await service.deleteConversation(id: id)
            conversations.removeAll { $0.id == id }
            if conversationId == id { startNewConversation() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reloadMessages(id: String, locale: String) async {
        do {
            let loaded = try await service.messages(
                id: id,
                page: 1,
                limit: 50,
                locale: locale
            )
            messages = loaded.sorted { $0.createdAt < $1.createdAt }
            pendingUserMessageID = retryMessage.flatMap { text in
                messages.last(where: { $0.role == .user && $0.content == text })?.id
            }
        } catch {
            errorMessage = "\(errorMessage ?? "")\n\(error.localizedDescription)"
        }
    }

    private func refreshConversations() async {
        do {
            conversations = try await service.conversations(page: 1, limit: 30)
        } catch {}
    }
}
