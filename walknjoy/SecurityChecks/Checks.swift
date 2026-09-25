import Foundation

// Standalone test doubles; compile this harness with the production files listed in README.
enum NetworkError: Error { case invalidResponse }

@MainActor
protocol ChangePasswordServiceProtocol {
    func requestPasswordChange(currentPassword: String) async throws -> ChangePasswordChallenge
    func verifyPasswordChange(code: String) async throws -> ChangePasswordAuthorization
    func changePassword(token: String, newPassword: String) async throws
}

@MainActor
final class AuthService: ChangePasswordServiceProtocol {
    var requests = 0
    var verifies = 0
    var saves = 0
    var failVerification = false
    func requestPasswordChange(currentPassword: String) async throws -> ChangePasswordChallenge {
        requests += 1
        try await Task.sleep(for: .milliseconds(10))
        return .init(expiresInSeconds: 600, resendAvailableInSeconds: 30)
    }
    func verifyPasswordChange(code: String) async throws -> ChangePasswordAuthorization {
        verifies += 1
        if failVerification { throw NetworkError.invalidResponse }
        return .init(changePasswordToken: "test-token")
    }
    func changePassword(token: String, newPassword: String) async throws {
        precondition(token == "test-token")
        saves += 1
    }
}

@MainActor final class TestClock {
    var date = Date(timeIntervalSince1970: 1000)
}

@main struct SecurityChecks {
    @MainActor static func main() async {
        let service = AuthService()
        let clock = TestClock()
        let model = SecurityViewModel(service: service, clock: { clock.date })
        await model.submit()
        precondition(service.requests == 0)
        model.currentPassword = "existing"
        let first = Task { await model.submit() }
        await Task.yield()
        await model.submit()
        await first.value
        precondition(service.requests == 1 && model.step == .code)
        await model.resend()
        precondition(service.requests == 1)
        clock.date = clock.date.addingTimeInterval(31)
        await model.resend()
        precondition(service.requests == 2 && model.codeSeconds == 600)
        model.code = "123"
        await model.submit()
        precondition(service.verifies == 0)
        model.code = "123456"
        service.failVerification = true
        await model.submit()
        precondition(model.step == .code)
        service.failVerification = false
        await model.submit()
        precondition(model.step == .newPassword && model.currentPassword.isEmpty)
        model.newPassword = "password1"
        model.confirmation = "different"
        await model.submit()
        precondition(service.saves == 0)
        model.confirmation = "password1"
        clock.date = clock.date.addingTimeInterval(601)
        await model.submit()
        precondition(service.saves == 0 && model.tokenExpired)
        model.restart()
        precondition(model.step == .currentPassword && model.newPassword.isEmpty)
        model.currentPassword = "existing"
        await model.submit()
        clock.date = clock.date.addingTimeInterval(601)
        model.code = "123456"
        await model.submit()
        precondition(model.step == .code && model.codeSeconds == 0)
        await model.resend()
        model.code = "123456"
        await model.submit()
        model.newPassword = "password1"
        model.confirmation = "password1"
        await model.submit()
        precondition(service.saves == 1 && model.step == .complete)
        precondition(model.newPassword.isEmpty && model.confirmation.isEmpty)
        await model.submit()
        precondition(service.saves == 1)
        print("PASS: request deduplication, validation, resend cooldown, OTP/token expiry, retry, successful change and secret cleanup")
    }
}
