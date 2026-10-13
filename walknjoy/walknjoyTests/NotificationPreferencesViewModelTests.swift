import Foundation
import Testing

@testable import walknjoy

@MainActor
struct NotificationPreferencesViewModelTests {
    @Test func initialStateBlocksSaving() async {
        let service = MockProfileService()
        let viewModel = NotificationPreferencesViewModel(service: service)

        guard case .idle = viewModel.state else {
            Issue.record("Expected initial idle state")
            return
        }
        #expect(viewModel.saveState == .idle)
        #expect(!viewModel.form.canSubmit)
        await viewModel.save()
        #expect(service.updateInputs.isEmpty)
    }

    @Test func loadSuccessAppliesPreferences() async {
        let service = MockProfileService()
        let viewModel = NotificationPreferencesViewModel(service: service)

        await viewModel.load()

        guard case .loaded(let preferences) = viewModel.state else {
            Issue.record("Expected loaded preferences")
            return
        }
        #expect(preferences.bookingUpdates)
        #expect(!preferences.messages)
        #expect(preferences.marketing)
        #expect(viewModel.bookingUpdates)
        #expect(!viewModel.messages)
        #expect(viewModel.marketing)
        #expect(service.loadCallCount == 1)
        #expect(!viewModel.form.canSubmit)
    }

    @Test func loadFailureShowsError() async {
        let service = MockProfileService()
        service.loadError = MockServiceError.failed
        let viewModel = NotificationPreferencesViewModel(service: service)

        await viewModel.load()

        guard case .error(let message) = viewModel.state else {
            Issue.record("Expected load error")
            return
        }
        #expect(message == MockServiceError.failed.localizedDescription)
        #expect(!viewModel.form.canSubmit)
        #expect(service.loadCallCount == 1)
    }

    @Test func loadRetriesAfterFailure() async {
        let service = MockProfileService()
        service.loadError = MockServiceError.failed
        let viewModel = NotificationPreferencesViewModel(service: service)
        await viewModel.load()

        service.loadError = nil
        await viewModel.load()

        guard case .loaded = viewModel.state else {
            Issue.record("Expected successful retry")
            return
        }
        #expect(service.loadCallCount == 2)
        #expect(viewModel.bookingUpdates)
    }

    @Test func loadDoesNotFetchAgainOnceLoaded() async {
        let service = MockProfileService()
        let viewModel = NotificationPreferencesViewModel(service: service)
        await viewModel.load()
        viewModel.messages = true

        await viewModel.load()

        #expect(service.loadCallCount == 1)
        #expect(viewModel.messages)
    }

    @Test func saveWithoutChangesDoesNotCallService() async {
        let service = MockProfileService()
        let viewModel = NotificationPreferencesViewModel(service: service)
        await viewModel.load()

        await viewModel.save()

        #expect(service.updateInputs.isEmpty)
        #expect(viewModel.saveState == .idle)
    }

    @Test func saveSuccessSendsChangesAndAppliesServerResponse() async throws {
        let service = MockProfileService()
        let viewModel = NotificationPreferencesViewModel(service: service)
        await viewModel.load()
        viewModel.messages = true
        service.updateResponse = Notification(
            bookingUpdates: false,
            messages: true,
            marketing: false
        )
        #expect(viewModel.form.canSubmit)

        await viewModel.save()

        #expect(service.updateInputs.count == 1)
        let input = try #require(service.updateInputs.first)
        #expect(input.bookingUpdates)
        #expect(input.messages)
        #expect(input.marketing)
        #expect(viewModel.saveState == .success)
        guard case .loaded(let preferences) = viewModel.state else {
            Issue.record("Expected saved preferences")
            return
        }
        #expect(!preferences.bookingUpdates)
        #expect(preferences.messages)
        #expect(!preferences.marketing)
        #expect(!viewModel.bookingUpdates)
        #expect(viewModel.messages)
        #expect(!viewModel.marketing)
        #expect(!viewModel.form.canSubmit)
    }

    @Test func saveFailurePreservesChangesAndAllowsRetry() async {
        let service = MockProfileService()
        let viewModel = NotificationPreferencesViewModel(service: service)
        await viewModel.load()
        viewModel.messages = true
        service.updateError = MockServiceError.failed

        await viewModel.save()

        #expect(
            viewModel.saveState
                == .error(MockServiceError.failed.localizedDescription)
        )
        #expect(viewModel.messages)
        guard case .loaded(let original) = viewModel.state else {
            Issue.record("Expected original preferences to remain loaded")
            return
        }
        #expect(!original.messages)
        #expect(viewModel.form.canSubmit)
        #expect(service.updateInputs.count == 1)

        service.updateError = nil
        await viewModel.save()

        #expect(service.updateInputs.count == 2)
        #expect(viewModel.saveState == .success)
        #expect(!viewModel.form.canSubmit)
    }
}

private nonisolated final class MockProfileService: ProfileServiceProtocol {
    var loadCallCount = 0
    var updateInputs: [walknjoy.Notification] = []
    var loadError: MockServiceError?
    var updateError: MockServiceError?
    var updateResponse: walknjoy.Notification?

    func getNotificationPreferences() async throws -> walknjoy.Notification {
        loadCallCount += 1
        if let loadError { throw loadError }
        return walknjoy.Notification(
            bookingUpdates: true,
            messages: false,
            marketing: true
        )
    }

    func updateNotification(_ input: walknjoy.Notification) async throws
        -> walknjoy.Notification
    {
        updateInputs.append(input)
        if let updateError { throw updateError }
        return updateResponse ?? input
    }

    func getProfile() async throws -> ProfileModel {
        throw MockServiceError.unexpectedCall
    }
    func updateProfile(_ input: UpdateProfileInput) async throws -> ProfileModel
    {
        throw MockServiceError.unexpectedCall
    }
    func updateAvatar(fileId: String, altText: String?) async throws
        -> AvatarResponse
    {
        throw MockServiceError.unexpectedCall
    }
    func deleteAvatar() async throws -> AvatarResponse {
        throw MockServiceError.unexpectedCall
    }
}

private nonisolated enum MockServiceError: LocalizedError {
    case failed
    case unexpectedCall

    var errorDescription: String? {
        switch self {
        case .failed: "Mock service failed"
        case .unexpectedCall: "Unexpected service call"
        }
    }
}
