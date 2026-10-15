import Foundation
import Observation

@MainActor
protocol ChatRealtimeProtocol: AnyObject {
    var state: NotificationSocketState { get }
    func subscribeChat(_ observer: @escaping (Data) -> Void) -> UUID
    func unsubscribeChat(_ id: UUID)
    func start()
    func sendChat(event: String, data: [String: String]) async throws
}
extension RealtimeClient: ChatRealtimeProtocol {}

@MainActor
@Observable
final class ChatDetailViewModel {
    let conversationID: String
    let userID: String
    private let service: ConversationServiceProtocol
    private let socket: ChatRealtimeProtocol
    private let locale: String
    private var subscription: UUID?
    private var generation = UUID()
    private var historyGeneration = UUID()
    private var active = false
    private var foreground = true
    private var joined = false
    private var sends: [String: Task<Void, Never>] = [:]
    private var typingTask: Task<Void, Never>?
    private var remoteTypingTask: Task<Void, Never>?
    private var visibleReadTask: Task<Void, Never>?
    private var loadedHistory = false
    private var lastVisibleID: String?
    private var lastReadID: String?
    private var readingID: String?
    private var readGeneration = UUID()
    private var typingSent = false
    private(set) var detail: ConversationDetail?
    private(set) var messages: [ChatMessage] = []
    private(set) var outgoing: [OutgoingMessage] = []
    private(set) var nextCursor: String?
    private(set) var state: LoadState<Void> = .idle
    private(set) var olderState: LoadState<Void> = .idle
    var isLoading: Bool { state.isLoading }
    var isLoadingOlder: Bool { olderState.isLoading }
    var hasLoadedHistory: Bool { loadedHistory }
    private(set) var otherIsTyping = false
    private(set) var receipt: ChatReadReceipt?
    private(set) var revision = 0
    private var actionError: String?
    var error: String? { state.errorMessage ?? olderState.errorMessage ?? actionError }
    var draft = ""
    var canSend: Bool {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !value.isEmpty && value.count <= 4000 && active && foreground
    }
    var isLive: Bool { joined && socket.state == .connected }
    var participant: ConversationParticipant? {
        detail?.otherParticipant(userID: userID)
    }

    init(
        id: String,
        userID: String,
        locale: String,
        service: ConversationServiceProtocol,
        socket: ChatRealtimeProtocol
    ) {
        conversationID = id
        self.userID = userID
        self.locale = locale
        self.service = service
        self.socket = socket
    }
    func activate() async {
        guard !active else { return }
        active = true
        subscription = socket.subscribeChat { [weak self] data in
            self?.receive(data)
        }
        Task { [weak self] in await self?.join() }
        await synchronize()
    }
    func stop() {
        active = false
        if state.isLoading { state = loadedHistory ? .loaded(()) : .idle }
        olderState = .idle
        visibleReadTask?.cancel()
        joined = false
        generation = UUID()
        historyGeneration = UUID()
        if let subscription { socket.unsubscribeChat(subscription) }
        subscription = nil
        typingTask?.cancel()
        remoteTypingTask?.cancel()
        readGeneration = UUID()
        typingSent = false
        otherIsTyping = false
        readingID = nil
        for task in sends.values { task.cancel() }
        sends = [:]
        for index in outgoing.indices { outgoing[index].status = .failed }
        let socket = socket
        let id = conversationID
        Task {
            try? await socket.sendChat(
                event: "typing:stop",
                data: ["conversationId": id]
            )
            try? await socket.sendChat(
                event: "chat:leave",
                data: ["conversationId": id]
            )
        }
    }
    func setForeground(_ value: Bool) {
        foreground = value
        guard active else { return }
        if value {
            Task {
                await join()
                await synchronize()
                await markVisibleRead()
            }
        } else {
            joined = false
            typingTask?.cancel()
            otherIsTyping = false
            typingSent = false
            readGeneration = UUID()
            readingID = nil
        }
    }
    private func join() async {
        guard active, foreground, socket.state == .connected else { return }
        try? await socket.sendChat(
            event: "chat:join",
            data: ["conversationId": conversationID]
        )
    }
    func synchronize() async {
        guard active, !state.isLoading else { return }
        if socket.state == .failed && foreground { socket.start() }
        let epoch = generation
        let history = UUID()
        historyGeneration = history
        defer {
            if generation == epoch, historyGeneration == history {
                if state.isLoading { state = loadedHistory ? .loaded(()) : .idle }
            }
        }
        state = .loading
        olderState = .idle
        actionError = nil
        do {
            let value = try await service.detail(
                id: conversationID,
                locale: locale
            )
            let page = try await service.messages(
                id: conversationID,
                before: nil
            )
            guard active, generation == epoch, historyGeneration == history
            else { return }
            detail = value
            messages = ChatFormatting.merge(messages, page.data)
            if !loadedHistory {
                nextCursor = page.meta.nextCursor
                loadedHistory = true
            }
            state = .loaded(())
            revision += 1
        } catch is CancellationError {} catch {
            guard active, generation == epoch, historyGeneration == history
            else { return }
            state = .error(error.localizedDescription)
        }
        guard generation == epoch, historyGeneration == history else { return }
        await markVisibleRead()
    }
    func loadOlder() async {
        guard active, !state.isLoading, !isLoadingOlder, let cursor = nextCursor else { return }
        let epoch = generation
        let history = historyGeneration
        olderState = .loading
        actionError = nil
        do {
            let page = try await service.messages(
                id: conversationID,
                before: cursor
            )
            guard active, generation == epoch, historyGeneration == history
            else { return }
            messages = ChatFormatting.merge(page.data, messages)
            nextCursor = page.meta.nextCursor
            olderState = .loaded(())
        } catch is CancellationError {} catch {
            if generation == epoch, historyGeneration == history { olderState = .error(error.localizedDescription) }
        }
        if generation == epoch, historyGeneration == history, olderState.isLoading { olderState = .idle }
    }
    func sendDraft() {
        guard canSend else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = OutgoingMessage(
            id: UUID().uuidString,
            content: content,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            status: .pending
        )
        outgoing.append(message)
        draft = ""
        draftChanged()
        revision += 1
        send(message)
    }
    func retry(_ id: String) {
        guard active, foreground,
            let index = outgoing.firstIndex(where: { $0.id == id }),
            sends[id] == nil
        else { return }
        outgoing[index].status = .pending
        send(outgoing[index])
    }
    private func send(_ message: OutgoingMessage) {
        let epoch = generation
        sends[message.id] = Task { [weak self] in
            guard let self else { return }
            if self.isLive {
                do {
                    try await self.socket.sendChat(
                        event: "message:send",
                        data: [
                            "conversationId": self.conversationID,
                            "content": message.content,
                            "clientMessageId": message.id,
                        ]
                    )
                    try await Task.sleep(for: .seconds(8))
                } catch is CancellationError { return } catch
                { /* REST fallback uses the same logical message identity. */  }
            }
            guard !Task.isCancelled, self.active, self.generation == epoch,
                self.outgoing.contains(where: { $0.id == message.id })
            else { return }
            do {
                let value = try await self.service.send(
                    id: self.conversationID,
                    content: message.content,
                    clientMessageId: message.id
                )
                guard self.active, self.generation == epoch, !Task.isCancelled
                else { return }
                self.acknowledge(clientID: message.id, message: value)
            } catch is CancellationError {} catch {
                guard self.active, self.generation == epoch, !Task.isCancelled
                else { return }
                if let index = self.outgoing.firstIndex(where: {
                    $0.id == message.id
                }) {
                    self.outgoing[index].status = .failed
                }
                self.sends[message.id] = nil
                self.actionError = error.localizedDescription
            }
        }
    }
    private func acknowledge(clientID: String, message: ChatMessage) {
        guard message.conversationId == conversationID else { return }
        messages = ChatFormatting.merge(messages, [message])
        outgoing.removeAll { $0.id == clientID }
        sends[clientID]?.cancel()
        sends[clientID] = nil
        revision += 1
    }
    func visibleMessages(_ ids: Set<String>) {
        guard let message = messages.last(where: { ids.contains($0.id) }),
            message.id != lastVisibleID
        else { return }
        if let current = lastVisibleID,
            let oldIndex = messages.firstIndex(where: { $0.id == current }),
            let index = messages.firstIndex(where: { $0.id == message.id }),
            oldIndex > index
        { return }
        lastVisibleID = message.id
        visibleReadTask?.cancel()
        visibleReadTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
            await self?.markVisibleRead()
        }
    }
    private func markVisibleRead() async {
        guard active, foreground, let id = lastVisibleID, id != lastReadID,
            readingID == nil
        else { return }
        let epoch = generation
        readingID = id
        let read = UUID()
        readGeneration = read
        defer {
            if readGeneration == read {
                readingID = nil
                if active, foreground, lastVisibleID != id {
                    Task { await markVisibleRead() }
                }
            }
        }
        do {
            let result = try await service.read(
                id: conversationID,
                messageId: id
            )
            guard active, foreground, generation == epoch,
                readGeneration == read
            else { return }
            lastReadID = id
            if result?.userId != userID { receipt = result }
            let refreshed = try await service.detail(
                id: conversationID,
                locale: locale
            )
            guard active, foreground, generation == epoch,
                readGeneration == read
            else { return }
            detail = refreshed
        } catch is CancellationError {} catch {
            if generation == epoch, readGeneration == read {
                self.actionError = error.localizedDescription
            }
        }
    }
    func isRead(_ message: ChatMessage) -> Bool {
        guard message.senderId == userID, let receipt, receipt.userId != userID,
            let lastID = receipt.lastReadMessageId,
            let last = messages.firstIndex(where: { $0.id == lastID }),
            let index = messages.firstIndex(where: { $0.id == message.id })
        else { return false }
        return index <= last
    }
    func draftChanged() {
        typingTask?.cancel()
        let empty = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        typingTask = Task { [weak self] in
            do {
                if !empty { try await Task.sleep(for: .milliseconds(400)) }
                guard let self, self.active, self.foreground, self.isLive else {
                    return
                }
                if empty {
                    if self.typingSent {
                        try? await self.socket.sendChat(
                            event: "typing:stop",
                            data: ["conversationId": self.conversationID]
                        )
                    }
                    self.typingSent = false
                } else {
                    if !self.typingSent {
                        try? await self.socket.sendChat(
                            event: "typing:start",
                            data: ["conversationId": self.conversationID]
                        )
                        self.typingSent = true
                    }
                    try await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    try? await self.socket.sendChat(
                        event: "typing:stop",
                        data: ["conversationId": self.conversationID]
                    )
                    self.typingSent = false
                }
            } catch {}
        }
    }
    private struct Header: Decodable { let event: String }
    private struct Envelope<T: Decodable>: Decodable { let data: T }
    private struct Room: Decodable {
        let conversationId: String
        let userId: String?
    }
    private struct Ack: Decodable {
        let clientMessageId: String
        let message: ChatMessage
    }
    private func receive(_ bytes: Data) {
        guard active else { return }
        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(Header.self, from: bytes) else {
            return
        }
        switch header.event {
        case "realtime:connected":
            joined = false
            Task {
                await join()
                await synchronize()
            }
        case "realtime:disconnected":
            joined = false
            otherIsTyping = false
            typingSent = false
        case "chat:joined":
            if let room = try? decoder.decode(Envelope<Room>.self, from: bytes),
                room.data.conversationId == conversationID
            {
                joined = true
            }
        case "message:new":
            if let message = try? decoder.decode(
                Envelope<ChatMessage>.self,
                from: bytes
            ).data, message.conversationId == conversationID {
                messages = ChatFormatting.merge(messages, [message])
                revision += 1
            }
        case "message:sent":
            if let ack = try? decoder.decode(Envelope<Ack>.self, from: bytes)
                .data
            {
                acknowledge(clientID: ack.clientMessageId, message: ack.message)
            }
        case "message:read":
            if let value = try? decoder.decode(
                Envelope<ChatReadReceipt>.self,
                from: bytes
            ).data,
                value.conversationId == conversationID, value.userId != userID
            {
                receipt = value
            }
        case "typing:start", "typing:stop":
            guard
                let room = try? decoder.decode(Envelope<Room>.self, from: bytes)
                    .data,
                room.conversationId == conversationID,
                let typingUser = room.userId, typingUser != userID
            else { return }
            remoteTypingTask?.cancel()
            otherIsTyping = header.event == "typing:start"
            remoteTypingTask = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(6)) } catch { return }
                self?.otherIsTyping = false
            }
        default: break
        }
    }
    isolated deinit {
        visibleReadTask?.cancel()
        typingTask?.cancel()
        remoteTypingTask?.cancel()
        for task in sends.values { task.cancel() }
    }
}
