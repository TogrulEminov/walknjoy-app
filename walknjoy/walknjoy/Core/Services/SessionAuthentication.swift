import Foundation

@MainActor
enum SessionAuthentication {
    static var onSessionExpired: (() -> Void)?
    private static var refreshTask: Task<Void, Error>?

    static func expire() { onSessionExpired?() }

    static func refresh() async throws {
        if refreshTask == nil {
            refreshTask = Task { try await AuthService().refresh() }
        }
        do {
            try await refreshTask?.value
            refreshTask = nil
        } catch {
            refreshTask = nil
            if error.isNotificationAuthenticationError { expire() }
            throw error
        }
    }
}
