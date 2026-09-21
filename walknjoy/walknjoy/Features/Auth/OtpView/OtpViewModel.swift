import Foundation
import Observation

@MainActor
@Observable
final class OtpViewModel {

    private let authService: AuthServiceProtocol

    var state: OtpViewState = .idle

    init(
        authService: AuthServiceProtocol = AuthService()
    ) {
        self.authService = authService
    }
    func resend(email: String) async {
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
