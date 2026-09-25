import Foundation
import Observation

@MainActor
@Observable
final class OtpViewModel {

    private let authService: AuthServiceProtocol

    var state: OtpViewState = .idle

    init(
        authService: AuthServiceProtocol? = nil
    ) {
        self.authService = authService ?? AuthService()
    }
    func resend(email: String) async {
        guard AuthForms.forgotPassword(email: email).canSubmit else { return }
        if case .loading = state { return }
        state = .loading

        do {
            let response = try await authService.forgotPassword(
                request: ForgotPasswordRequest(email: email)
            )

            state = .resendSuccess(
                expiresInSeconds: response.expiresInSeconds,
                resendAvailableInSeconds: response.resendAvailableInSeconds
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    func verify(
        email: String,
        code: String
    ) async {

        guard AuthForms.otp(code: code).canSubmit else { return }
        if case .loading = state { return }
        state = .loading

        do {

            let request =
                VerifyForgotPasswordOTPRequest(
                    email: email,
                    code: code
                )

            let response =
                try await authService
                .verifyForgotPasswordOTP(
                    request: request
                )

            state = .success(
                resetToken: response.resetToken
            )

        } catch {

            state = .error(
                error.localizedDescription
            )
        }
    }
}
