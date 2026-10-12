import Foundation
import OSLog

enum NotificationSocketState: Equatable {
    case disconnected, connecting, connected, reconnecting, failed
}

protocol NotificationSocketProtocol: AnyObject {
    var onStateChange: ((NotificationSocketState) -> Void)? { get set }
    var onNotification: ((AppNotification) -> Void)? { get set }
    var onConnected: (() -> Void)? { get set }
    var onAuthenticationRequired: (() -> Void)? { get set }
    func start()
    func stop()
}
final class RealtimeClient: NotificationSocketProtocol {
    var onStateChange: ((NotificationSocketState) -> Void)?
    var onNotification: ((AppNotification) -> Void)?
    var onConnected: (() -> Void)?
    var onAuthenticationRequired: (() -> Void)?
    private(set) var state: NotificationSocketState = .disconnected {
        didSet { onStateChange?(state) }
    }
    private var chatObservers: [UUID: (Data) -> Void] = [:]
    func subscribeChat(_ observer: @escaping (Data) -> Void) -> UUID {
        let id = UUID()
        chatObservers[id] = observer
        return id
    }
    func unsubscribeChat(_ id: UUID) { chatObservers[id] = nil }
    func sendChat(event: String, data: [String: String]) async throws {
        guard state == .connected, let socket else {
            throw URLError(.networkConnectionLost)
        }
        let bytes = try JSONSerialization.data(withJSONObject: [
            "event": event, "data": data,
        ])
        guard let text = String(data: bytes, encoding: .utf8) else {
            throw NetworkError.encodingError
        }
        try await socket.send(.string(text))
    }
    private func broadcastChat(_ data: Data) {
        for callback in Array(chatObservers.values) { callback(data) }
    }
    func clearChatSubscriptions() { chatObservers = [:] }
    private let tokens: TokenStorageProtocol
    private let baseURL: String
    private var session: URLSession?
    private var socket: URLSessionWebSocketTask?
    private var retryTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var running = false
    private var attempt = 0
    private var generation = UUID()
    private let logger = Logger(
        subsystem: "walknjoy",
        category: "realtime-socket"
    )

    init(tokens: TokenStorageProtocol? = nil, baseURL: String? = nil) {
        self.tokens = tokens ?? TokenStorage()
        self.baseURL = baseURL ?? APIConfig.baseURL
    }

    static func retryDelay(attempt: Int) -> UInt64 {
        [1, 2, 5, 10, 30][min(max(0, attempt), 4)]
    }

    static func request(baseURL: String, token: String) throws -> URLRequest {
        guard !token.isEmpty, var url = URLComponents(string: baseURL),
            url.host != nil, ["https", "http"].contains(url.scheme ?? ""),
            url.user == nil, url.password == nil
        else { throw NetworkError.invalidURL }
        url.scheme = url.scheme == "https" ? "wss" : "ws"
        url.path = url.path.trimmingCharacters(
            in: CharacterSet(charactersIn: "/")
        )
        url.path = "/" + url.path + "/ws"
        url.query = nil
        url.fragment = nil
        guard let endpoint = url.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    func start() {
        #if DEBUG
        if DemoBackend.shared.isActive { return }
        #endif
        guard !running else { return }
        running = true
        attempt = 0
        open()
    }

    func stop() {
        running = false
        generation = UUID()
        retryTask?.cancel()
        retryTask = nil
        closeTransport()
        state = .disconnected
        broadcastChat(
            Data(#"{"event":"realtime:disconnected","data":{}}"#.utf8)
        )
    }

    private func open() {
        guard running else { return }
        guard let token = tokens.accessToken else {
            authenticationRequired()
            return
        }
        closeTransport()
        let id = UUID()
        generation = id
        do {
            let request = try Self.request(baseURL: baseURL, token: token)
            let delegate = NotificationSocketDelegate()
            delegate.didOpen = { [weak self] task in
                guard let self, self.generation == id, self.running,
                    self.socket === task
                else { return }
                self.timeoutTask?.cancel()
                self.state = .connected
                self.onConnected?()
                self.broadcastChat(
                    Data(#"{"event":"realtime:connected","data":{}}"#.utf8)
                )
                self.ping(id: id)
            }
            delegate.didFinish = { [weak self] task in
                self?.failed(task: task, id: id)
            }
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            configuration.urlCredentialStorage = nil
            configuration.timeoutIntervalForRequest = 15
            let session = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
            self.session = session
            let task = session.webSocketTask(with: request)
            task.maximumMessageSize = 1_048_576
            socket = task
            state = attempt == 0 ? .connecting : .reconnecting
            task.resume()
            receive(task: task, id: id)
            timeoutTask = Task { [weak self, weak task] in
                do { try await Task.sleep(for: .seconds(15)) } catch { return }
                guard let task else { return }
                self?.failed(task: task, id: id)
            }
        } catch {
            state = .failed
            scheduleReconnect()
        }
    }

    private func receive(task: URLSessionWebSocketTask, id: UUID) {
        task.receive { [weak self, weak task] result in
            Task { @MainActor [weak self, weak task] in
                guard let self, let task, self.running, self.generation == id
                else { return }
                switch result {
                case .success(let message):
                    let data: Data
                    switch message {
                    case .string(let text): data = Data(text.utf8)
                    case .data(let bytes): data = bytes
                    @unknown default:
                        self.receive(task: task, id: id)
                        return
                    }
                    self.broadcastChat(data)
                    do {
                        if let notification =
                            try NotificationEventDecoder.notification(
                                from: data
                            )
                        {
                            self.onNotification?(notification)
                        }
                    } catch {

                        self.logger.error(
                            "Ignored malformed notification frame"
                        )
                    }
                    self.receive(task: task, id: id)
                case .failure: self.failed(task: task, id: id)
                }
            }
        }
    }

    private func ping(id: UUID) {
        guard running, generation == id, let task = socket else { return }
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self, weak task] in
            do { try await Task.sleep(for: .seconds(10)) } catch { return }
            guard let task else { return }
            self?.failed(task: task, id: id)
        }
        task.sendPing { [weak self, weak task] error in
            let failed = error != nil
            Task { @MainActor [weak self, weak task] in
                guard let self, let task, self.running, self.generation == id
                else { return }
                self.timeoutTask?.cancel()
                if failed {
                    self.failed(task: task, id: id)
                    return
                }
                self.attempt = 0
                self.heartbeatTask = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(25)) } catch {
                        return
                    }
                    self?.ping(id: id)
                }
            }
        }
    }

    private func failed(task: URLSessionWebSocketTask, id: UUID) {
        guard running, generation == id, socket === task else { return }
        let status = (task.response as? HTTPURLResponse)?.statusCode
        let code = task.closeCode.rawValue
        if status == 401 || status == 403 || [1008, 4401, 4403].contains(code) {
            authenticationRequired()
            return
        }
        generation = UUID()
        broadcastChat(
            Data(#"{"event":"realtime:disconnected","data":{}}"#.utf8)
        )
        closeTransport()
        state = attempt >= 4 ? .failed : .reconnecting
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard running else { return }
        guard attempt < 5 else {
            running = false
            state = .failed
            return
        }
        let delay = Self.retryDelay(attempt: attempt)
        attempt += 1
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            self?.open()
        }
    }

    private func authenticationRequired() {
        stop()
        onAuthenticationRequired?()
    }
    private func closeTransport() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        session?.invalidateAndCancel()
        session = nil
    }
    deinit {
        retryTask?.cancel()
        heartbeatTask?.cancel()
        timeoutTask?.cancel()
        socket?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel()
    }
}

@MainActor
private final class NotificationSocketDelegate: NSObject,
    URLSessionWebSocketDelegate
{
    var didOpen: ((URLSessionWebSocketTask) -> Void)?
    var didFinish: ((URLSessionWebSocketTask) -> Void)?

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { @MainActor [weak self] in self?.didOpen?(webSocketTask) }
    }
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { @MainActor [weak self] in self?.didFinish?(webSocketTask) }
    }
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let task = task as? URLSessionWebSocketTask else { return }
        Task { @MainActor [weak self] in self?.didFinish?(task) }
    }
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
