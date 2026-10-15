import Foundation
import Testing

@testable import walknjoy

@MainActor
struct ChatLoadingTests {
    @Test func mergeDeduplicatesAndSortsEquivalentTimestampFormats() {
        func message(_ id: String, _ date: String, _ content: String = "text") -> ChatMessage {
            ChatMessage(id: id, conversationId: "chat", senderId: "user", content: content, createdAt: date)
        }
        let result = ChatFormatting.merge(
            [message("b", "2026-10-14T12:00:00Z"), message("a", "2026-10-14T12:00:00.000Z")],
            [message("b", "2026-10-14T12:00:00Z", "updated"), message("c", "2026-10-14T12:00:01Z")]
        )
        #expect(result.map(\.id) == ["a", "b", "c"])
        #expect(result[1].content == "updated")
    }

    @Test func chatCoalescesSynchronizationAndMarksOnlyNewestVisibleMessage() async throws {
        let service = SuspendedConversationService()
        let model = ChatDetailViewModel(
            id: "chat", userID: "user", locale: "az",
            service: service, socket: OfflineChatSocket()
        )
        await model.activate()
        #expect(service.detailRequests == 1)
        #expect(model.messages.count == 3)

        service.suspendDetail = true
        let refresh = Task { await model.synchronize() }
        while service.pendingDetail == nil { await Task.yield() }
        await model.synchronize()
        #expect(service.detailRequests == 2)
        service.pendingDetail?.resume(returning: service.chatDetail)
        service.pendingDetail = nil
        await refresh.value
        service.suspendDetail = false

        model.visibleMessages(["a", "b"])
        model.visibleMessages(["a", "b", "c"])
        model.visibleMessages(["a", "b", "c"])
        try await Task.sleep(for: .milliseconds(350))
        #expect(service.readIDs == ["c"])
        model.visibleMessages(["a"])
        try await Task.sleep(for: .milliseconds(250))
        #expect(service.readIDs == ["c"])
        model.stop()
    }

    @Test func delayedChatUsesLoadingThenErrorAndCanRetry() async throws {
        let service = SuspendedConversationService()
        service.suspendDetail = true
        let model = ChatDetailViewModel(
            id: "chat", userID: "user", locale: "az",
            service: service, socket: OfflineChatSocket()
        )
        #expect(isIdle(model.state))
        let loading = Task { await model.activate() }
        while service.pendingDetail == nil { await Task.yield() }
        #expect(model.state.isLoading)
        #expect(!model.hasLoadedHistory)
        service.pendingDetail?.resume(throwing: URLError(.timedOut))
        service.pendingDetail = nil
        await loading.value
        #expect(model.state.errorMessage != nil)
        #expect(!model.isLoading)
        service.suspendDetail = false
        await model.synchronize()
        #expect(isLoaded(model.state))
        #expect(model.hasLoadedHistory)
        model.stop()
    }

    @Test func cancellationClearsInitialLoading() async {
        let service = SuspendedConversationService()
        service.suspend = true
        let model = ConversationListViewModel(service: service)
        let loading = Task { await model.refresh(locale: "az") }
        while service.pending == nil { await Task.yield() }
        #expect(model.state.isLoading)
        service.pending?.resume(throwing: CancellationError())
        service.pending = nil
        await loading.value
        #expect(isIdle(model.state))
        #expect(!model.isLoading)
    }

    @Test func refreshKeepsNavigationRowsAndCoalescesConcurrentRefreshes() async throws {
        let service = SuspendedConversationService()
        let model = ConversationListViewModel(service: service)
        await model.refresh(locale: "az")
        #expect(model.rows.map(\.id) == ["chat"])

        service.suspend = true
        let refresh = Task { await model.refresh(locale: "az") }
        while service.pending == nil { await Task.yield() }
        #expect(model.rows.map(\.id) == ["chat"])
        #expect(model.isLoading)
        await model.refresh(locale: "az")
        #expect(service.requests == 2)
        service.pending?.resume(throwing: URLError(.notConnectedToInternet))
        service.pending = nil
        await refresh.value
        #expect(model.rows.map(\.id) == ["chat"])
        #expect(!model.isLoading)
        #expect(model.error != nil)
    }
}

@MainActor
private final class SuspendedConversationService: ConversationServiceProtocol {
    var detailRequests = 0
    var suspendDetail = false
    var pendingDetail: CheckedContinuation<ConversationDetail, Error>?
    var readIDs: [String] = []
    var chatDetail: ConversationDetail {
        ConversationDetail(
            id: "chat", context: ConversationContext(type: "listing", listing: nil, bookingId: nil),
            participants: [], unreadCount: 3,
            createdAt: "2026-10-14T12:00:00Z", updatedAt: "2026-10-14T12:00:00Z"
        )
    }
    var requests = 0
    var suspend = false
    var pending: CheckedContinuation<ConversationPage, Error>?
    func list(page: Int, locale: String) async throws -> ConversationPage {
        requests += 1
        if suspend {
            return try await withCheckedThrowingContinuation { pending = $0 }
        }
        let row = ConversationRow(
            id: "chat",
            context: ConversationContext(type: "listing", listing: nil, bookingId: nil),
            otherParticipant: ConversationParticipant(id: "other", displayName: "Other", avatarFile: nil),
            lastMessage: nil, unreadCount: 1, updatedAt: "2026-10-14T12:00:00Z"
        )
        return ConversationPage(items: [row], meta: PaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1))
    }
    func detail(id: String, locale: String) async throws -> ConversationDetail {
        detailRequests += 1
        if suspendDetail {
            return try await withCheckedThrowingContinuation { pendingDetail = $0 }
        }
        return chatDetail
    }
    func start(_ context: ConversationStart, locale: String) async throws -> ConversationDetail { throw URLError(.unsupportedURL) }
    func messages(id: String, before: String?) async throws -> MessagePage {
        MessagePage(success: true, data: ["a", "b", "c"].map {
            ChatMessage(id: $0, conversationId: id, senderId: "other", content: $0, createdAt: "2026-10-14T12:00:00Z")
        }, meta: MessagePage.Meta(nextCursor: nil))
    }
    func send(id: String, content: String, clientMessageId: String) async throws -> ChatMessage { throw URLError(.unsupportedURL) }
    func read(id: String, messageId: String) async throws -> ChatReadReceipt? {
        readIDs.append(messageId)
        return nil
    }
}

@MainActor
private final class OfflineChatSocket: ChatRealtimeProtocol {
    var state: NotificationSocketState { .disconnected }
    func subscribeChat(_ observer: @escaping (Data) -> Void) -> UUID { UUID() }
    func unsubscribeChat(_ id: UUID) {}
    func start() {}
    func sendChat(event: String, data: [String: String]) async throws {}
}

private func isIdle(_ state: LoadState<Void>) -> Bool {
    if case .idle = state { return true }
    return false
}

private func isLoaded(_ state: LoadState<Void>) -> Bool {
    if case .loaded = state { return true }
    return false
}
