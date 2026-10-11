import Foundation
import Observation

@MainActor
@Observable
final class OtpViewModel {

    private let authService: AuthServiceProtocol

    var state: OtpViewState = .idle
    private(set) var otpRemainingSeconds: Int
    private(set) var resendRemainingSeconds: Int
    private(set) var otpTimerID = UUID()
    private(set) var resendTimerID = UUID()
    private var otpDeadline: Date
    private var resendDeadline: Date
    var isOtpExpired: Bool { otpRemainingSeconds <= 0 }
    var formattedExpireTime: String { Self.format(otpRemainingSeconds) }
    var formattedResendTime: String { Self.format(resendRemainingSeconds) }


    init(
        authService: AuthServiceProtocol? = nil,
        expireTime: Int = 300,
        resendAvailableTime: Int = 0
    ) {
        self.authService = authService ?? AuthService()
        otpRemainingSeconds = max(0, expireTime)
        resendRemainingSeconds = max(0, resendAvailableTime)
        otpDeadline = Date().addingTimeInterval(TimeInterval(max(0, expireTime)))
        resendDeadline = Date().addingTimeInterval(TimeInterval(max(0, resendAvailableTime)))
    }
    func resend(email: String) async {
        guard resendRemainingSeconds == 0, AuthForms.forgotPassword(email: email).canSubmit else { return }
        if case .loading = state { return }
        state = .loading

        do {
            let response = try await authService.forgotPassword(
                request: ForgotPasswordRequest(email: email)
            )

            resetCountdowns(expires: response.expiresInSeconds, resend: response.resendAvailableInSeconds)
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

        guard !isOtpExpired, AuthForms.otp(code: code).canSubmit else { return }
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

// Countdown state belongs to the feature model, and uses deadlines to survive backgrounding.
extension OtpViewModel {
    func startOtpTimer() async { await runCountdown(isOTP: true) }
    func startResendTimer() async { await runCountdown(isOTP: false) }

    private func runCountdown(isOTP: Bool) async {
        let token = isOTP ? otpTimerID : resendTimerID
        while !Task.isCancelled {
            guard token == (isOTP ? otpTimerID : resendTimerID) else { return }
            let deadline = isOTP ? otpDeadline : resendDeadline
            let remaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
            if isOTP { otpRemainingSeconds = remaining } else { resendRemainingSeconds = remaining }
            guard remaining > 0 else { return }
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
        }
    }

    private func resetCountdowns(expires: Int, resend: Int) {
        otpRemainingSeconds = max(0, expires)
        resendRemainingSeconds = max(0, resend)
        otpDeadline = Date().addingTimeInterval(TimeInterval(otpRemainingSeconds))
        resendDeadline = Date().addingTimeInterval(TimeInterval(resendRemainingSeconds))
        otpTimerID = UUID()
        resendTimerID = UUID()
    }
    private static func format(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
}
