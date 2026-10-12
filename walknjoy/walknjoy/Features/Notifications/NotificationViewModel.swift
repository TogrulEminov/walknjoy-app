import Foundation
import Observation

@MainActor @Observable
final class NotificationViewModel {
    private(set) var notifications: [AppNotification] = []
    private(set) var unreadCount = 0
    private(set) var socketState: NotificationSocketState = .disconnected
    private(set) var isLoading = false
    private(set) var isMarkingRead = false
    private var paginationMeta: PaginationMeta?
    var visibleNotifications: [AppNotification] {
        notifications.filter { !unreadOnly || !$0.isRead }
    }
    var hasMore: Bool { paginationMeta?.hasNextPage ?? false }
    private(set) var unreadOnly = false
    var error: String?
    var onSessionExpired: (() -> Void)?

    private let service: NotificationServiceProtocol
    private let socket: NotificationSocketProtocol
    private let auth: AuthServiceProtocol
    private let tokens: TokenStorageProtocol
    private var active = false
    private var signedIn = false
    private var ownerID: String?
    private var epoch = UUID()
    private var revision = 0
    private var receivedIDs: Set<String> = []
    private var syncTask: Task<Void, Never>?
    private var authTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var needsSync = false
    private var refreshAttempts = 0
    private var refreshedAt: Date?

    init(
        service: NotificationServiceProtocol? = nil,
        socket: NotificationSocketProtocol? = nil,
        auth: AuthServiceProtocol? = nil,
        tokens: TokenStorageProtocol? = nil
    ) {
        self.service = service ?? NotificationService()
        self.socket = socket ?? RealtimeClient()
        self.auth = auth ?? AuthService()
        self.tokens = tokens ?? TokenStorage()
        self.socket.onStateChange = { [weak self] state in
            self?.socketState = state
        }
        self.socket.onNotification = { [weak self] notification in
            self?.receive(notification)
        }
        self.socket.onConnected = { [weak self] in self?.requestSync() }
        self.socket.onAuthenticationRequired = { [weak self] in
            self?.recoverAuthentication()
        }
    }

    func startSession() {
        guard !signedIn else {
            resume()
            return
        }
        signedIn = true
        resume()
    }
    func resume() {
        guard signedIn, !active else { return }
        active = true
        if ownerID == nil {
            verifySession()
        } else {
            socket.start()
            requestSync()
        }
        schedulePoll()
    }
    func suspend() {
        active = false
        epoch = UUID()
        socket.stop()
        syncTask?.cancel()
        syncTask = nil
        authTask?.cancel()
        authTask = nil
        pollTask?.cancel()
        pollTask = nil
        isLoading = false
        isMarkingRead = false
    }
    func endSession() {
        signedIn = false
        suspend()
        ownerID = nil
        notifications = []
        unreadCount = 0
        receivedIDs = []
        paginationMeta = nil
        error = nil
        refreshAttempts = 0
        refreshedAt = nil
        unreadOnly = false
        needsSync = false
        revision += 1
    }

    private func verifySession() {
        guard active, authTask == nil else { return }
        let id = epoch
        authTask = Task { [weak self, auth] in
            do {
                let user = try await auth.me()
                guard let self, self.epoch == id, self.active else { return }
                self.authTask = nil
                self.ownerID = user.id
                self.socket.start()
                self.requestSync()
            } catch {
                guard let self, self.epoch == id else { return }
                self.authTask = nil
                if error.isNotificationAuthenticationError {
                    self.recoverAuthentication()
                } else if error is MobileAccountAccess.AccessError {
                    self.expireSession()
                } else {
                    self.error = String(localized: "notifications.loadError")
                }
            }
        }
    }

    private func recoverAuthentication() {
        guard active, authTask == nil else { return }
        socket.stop()
        if let refreshedAt, Date().timeIntervalSince(refreshedAt) >= 30 {
            refreshAttempts = 0
        }
        guard refreshAttempts == 0 else {
            expireSession()
            return
        }
        refreshAttempts += 1
        refreshedAt = Date()
        // Retire all work authenticated with the expired token before refreshing it.
        epoch = UUID()
        syncTask?.cancel()
        syncTask = nil
        isLoading = false
        isMarkingRead = false
        let id = epoch
        authTask = Task { [weak self, auth] in
            do {
                try await auth.refresh()
                let user = try await auth.me()
                guard let self, self.epoch == id, self.active else { return }
                self.authTask = nil
                guard self.ownerID == nil || self.ownerID == user.id else {
                    self.expireSession()
                    return
                }
                self.ownerID = user.id
                self.socket.start()
                self.requestSync()
            } catch {
                guard let self, self.epoch == id else { return }
                self.authTask = nil
                if error.isNotificationAuthenticationError
                    || error is MobileAccountAccess.AccessError
                {
                    self.expireSession()
                } else {
                    self.refreshAttempts = 0
                    self.error = String(localized: "notifications.loadError")
                }
            }
        }
    }
    private func expireSession() {
        endSession()
        try? tokens.clear()
        onSessionExpired?()
    }

    func setUnreadOnly(_ value: Bool) {
        guard unreadOnly != value else { return }
        unreadOnly = value
        revision += 1
        requestSync()
    }

    func requestSync() {
        guard active, ownerID != nil else { return }
        needsSync = true
        guard syncTask == nil, !isMarkingRead, !isLoading else { return }
        let id = epoch
        syncTask = Task { [weak self] in
            await self?.synchronize(epoch: id)
        }
    }
    func refresh() async {
        if ownerID == nil {
            verifySession()
            return
        }
        requestSync()
        await syncTask?.value
    }
    private func synchronize(epoch id: UUID) async {
        guard active, epoch == id, !Task.isCancelled else { return }
        isLoading = true
        defer {
            if epoch == id {
                isLoading = false
                syncTask = nil
            }
        }
        // A socket event or read mutation during a REST request invalidates that snapshot.
        // Bounded retries avoid starving the UI under a stream of notifications.
        for _ in 0..<3 {
            guard active, epoch == id, !isMarkingRead else { return }
            needsSync = false
            let version = revision
            do {
                async let history = service.list(
                    unreadOnly: unreadOnly,
                    page: 1
                )
                async let count = service.unreadCount()
                let snapshot = try await (history, count)
                guard active, epoch == id, !Task.isCancelled else { return }
                guard revision == version, !isMarkingRead else {
                    needsSync = true
                    continue
                }
                var ids: Set<String> = []
                notifications = snapshot.0.items.filter {
                    ids.insert($0.id).inserted
                }
                receivedIDs.formUnion(ids)
                unreadCount = snapshot.1
                paginationMeta = snapshot.0.meta
                error = nil
                if !needsSync { return }
            } catch {
                guard epoch == id, !Task.isCancelled else { return }
                if error.isNotificationAuthenticationError {
                    recoverAuthentication()
                } else {
                    self.error = String(localized: "notifications.loadError")
                }
                return
            }
        }
    }

    func loadMore() async {
        guard active, ownerID != nil, hasMore, syncTask == nil, !isLoading,
            !isMarkingRead
        else { return }
        isLoading = true
        let id = epoch
        let version = revision
        let next = (paginationMeta?.page ?? 1) + 1
        defer { if epoch == id { isLoading = false } }
        do {
            let result = try await service.list(
                unreadOnly: unreadOnly,
                page: next
            )
            guard epoch == id, active, revision == version else { return }
            var ids = Set(notifications.map(\.id))
            notifications += result.items.filter { ids.insert($0.id).inserted }
            receivedIDs.formUnion(ids)
            paginationMeta = result.meta
        } catch {
            guard epoch == id else { return }
            if error.isNotificationAuthenticationError {
                recoverAuthentication()
            } else {
                self.error = String(localized: "notifications.loadError")
            }
        }
    }

    private func receive(_ notification: AppNotification) {
        guard active, ownerID != nil,
            receivedIDs.insert(notification.id).inserted
        else { return }
        notifications.insert(notification, at: 0)
        if !notification.isRead { unreadCount += 1 }
        revision += 1
    }

    @discardableResult func markRead(_ notification: AppNotification) async
        -> Bool
    {
        guard active, ownerID != nil, !isMarkingRead else { return false }
        guard
            let current = notifications.first(where: {
                $0.id == notification.id
            })
        else { return false }
        guard !current.isRead else { return true }
        isMarkingRead = true
        revision += 1
        let id = epoch
        defer {
            if epoch == id {
                isMarkingRead = false
                requestSync()
            }
        }
        do {
            try await service.markRead(id: notification.id)
            guard epoch == id, active else { return false }
            if let index = notifications.firstIndex(where: {
                $0.id == notification.id && $0.isRead
            }) {
                notifications[index].isRead = true
                unreadCount = max(0, unreadCount - 1)
            }
            revision += 1
            error = nil
            return true
        } catch {
            guard epoch == id else { return false }
            if error.isNotificationAuthenticationError {
                recoverAuthentication()
            } else {
                self.error = String(localized: "notifications.updateError")
            }
            return false
        }
    }

    func markAllRead() async {
        guard active, ownerID != nil, !isMarkingRead, unreadCount > 0 else {
            return
        }
        isMarkingRead = true
        revision += 1
        let id = epoch
        let ids = Set(notifications.map(\.id))
        let count = unreadCount
        defer {
            if epoch == id {
                isMarkingRead = false
                requestSync()
            }
        }
        do {
            try await service.markAllRead()
            guard epoch == id, active else { return }
            for index in notifications.indices
            where ids.contains(notifications[index].id) {
                notifications[index].isRead = true
            }
            unreadCount = max(0, unreadCount - count)
            revision += 1
            error = nil
        } catch {
            guard epoch == id else { return }
            if error.isNotificationAuthenticationError {
                recoverAuthentication()
            } else {
                self.error = String(localized: "notifications.updateError")
            }
        }
    }

    private func schedulePoll() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            guard let self, self.active else { return }
            if self.ownerID == nil {
                self.verifySession()
            } else {
                self.requestSync()
            }
            self.schedulePoll()
        }
    }

    isolated deinit {
        syncTask?.cancel()
        authTask?.cancel()
        pollTask?.cancel()
        socket.stop()
    }
}
