import Foundation
import Observation

@MainActor
@Observable
final class NotificationPreferencesViewModel {
    enum Field { case bookingUpdates, messages, aiUpdates, marketing }

    private let service: ProfileServiceProtocol
    private(set) var state: LoadState<Notification> = .idle
    private(set) var saveState: RequestState = .idle

    var bookingUpdates = false
    var messages = false
    var aiUpdates = false
    var marketing = false

    init(service: ProfileServiceProtocol? = nil) {
        self.service = service ?? ProfileService()
    }

    var form: FormState<Field> {
        guard case .loaded(let original) = state else {
            return FormState(fields: [:], isBlocked: true)
        }
        return FormState(fields: [
            .bookingUpdates: .toggle(bookingUpdates, originalValue: original.bookingUpdates),
            .messages: .toggle(messages, originalValue: original.messages),
            .aiUpdates: .toggle(aiUpdates, originalValue: original.aiUpdates),
            .marketing: .toggle(marketing, originalValue: original.marketing)
        ], isSubmitting: saveState == .loading, requiresChanges: true)
    }

    func load() async {
        switch state {
        case .loading, .loaded: return
        case .idle, .error: break
        }
        state = .loading
        do {
            apply(try await service.getNotificationPreferences())
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func save() async {
        guard form.canSubmit else { return }
        saveState = .loading
        let input = Notification(
            bookingUpdates: bookingUpdates, messages: messages,
            aiUpdates: aiUpdates, marketing: marketing
        )
        do {
            apply(try await service.updateNotification(input))
            saveState = .success
        } catch {
            // Preserve the user's selections so a failed save can be retried.
            saveState = .error(error.localizedDescription)
        }
    }

    private func apply(_ preferences: Notification) {
        bookingUpdates = preferences.bookingUpdates
        messages = preferences.messages
        aiUpdates = preferences.aiUpdates
        marketing = preferences.marketing
        state = .loaded(preferences)
    }
}
