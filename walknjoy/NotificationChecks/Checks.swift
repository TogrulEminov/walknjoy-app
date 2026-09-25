import Foundation

protocol ProfileServiceProtocol {
    func getNotificationPreferences() async throws -> Notification
    func updateNotification(_ input: Notification) async throws -> Notification
}

final class ProfileService: ProfileServiceProtocol {
    enum Failure: Error { case offline }
    var reads = 0
    var writes = 0
    var failLoad = true
    var failSave = false
    var stored = Notification(bookingUpdates: true, messages: false, aiUpdates: true, marketing: false)

    func getNotificationPreferences() async throws -> Notification {
        reads += 1
        if failLoad { throw Failure.offline }
        return stored
    }

    func updateNotification(_ input: Notification) async throws -> Notification {
        writes += 1
        try await Task.sleep(for: .milliseconds(10))
        if failSave { throw Failure.offline }
        stored = input
        return stored
    }
}

@main struct NotificationChecks {
    @MainActor static func main() async {
        let service = ProfileService()
        let model = NotificationPreferencesViewModel(service: service)
        precondition(!model.form.canSubmit)
        await model.load()
        guard case .error = model.state else { fatalError("Expected load failure") }
        service.failLoad = false
        await model.load()
        precondition(model.bookingUpdates && !model.messages && model.aiUpdates && !model.marketing)
        precondition(!model.form.canSubmit)
        await model.save()
        precondition(service.writes == 0)
        model.messages = true
        precondition(model.form.canSubmit)
        model.messages = false
        precondition(!model.form.canSubmit)
        model.marketing = true
        service.failSave = true
        await model.save()
        precondition(model.marketing && model.form.canSubmit)
        service.failSave = false
        let task = Task { await model.save() }
        await Task.yield()
        await model.save()
        await task.value
        precondition(service.writes == 2 && service.stored.marketing)
        precondition(model.saveState == .success && !model.form.canSubmit)
        await model.load()
        precondition(service.reads == 2)
        print("PASS: load retry, server values, unchanged/reverted saves, failed-save preservation, duplicate protection, baseline update")
    }
}
