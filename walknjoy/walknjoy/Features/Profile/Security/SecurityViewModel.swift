import Foundation
import Observation

@MainActor
@Observable
final class SecurityViewModel {
    enum Step { case currentPassword, code, newPassword, complete }
    enum Field { case currentPassword, code, password, confirmation }

    private let service: ChangePasswordServiceProtocol
    private let clock: () -> Date
    private var codeDeadline: Date?
    private var resendDeadline: Date?
    private var tokenDeadline: Date?
    private var token: String?

    private(set) var step: Step = .currentPassword
    private(set) var state: RequestState = .idle
    var currentPassword = ""
    var code = ""
    var newPassword = ""
    var confirmation = ""
    private(set) var now: Date

    init(service: ChangePasswordServiceProtocol? = nil, clock: @escaping () -> Date = { Date() }) {
        self.service = service ?? AuthService()
        self.clock = clock
        self.now = clock()
    }

    var isLoading: Bool { state == .loading }
    var codeSeconds: Int { remaining(codeDeadline) }
    var resendSeconds: Int { remaining(resendDeadline) }
    var tokenExpired: Bool { step == .newPassword && remaining(tokenDeadline) == 0 }
    var canResend: Bool { step == .code && resendSeconds == 0 && !isLoading }

    var form: FormState<Field> {
        let fields: [Field: ValidatedField]
        var blocked = false
        switch step {
        case .currentPassword:
            fields = [.currentPassword: ValidatedField(value: currentPassword, rules: [.required("security.current.required")])]
        case .code:
            fields = [.code: ValidatedField(value: code, rules: [.digits(6, message: "otp.validation.code")])]
            blocked = codeSeconds == 0
        case .newPassword:
            fields = [
                .password: ValidatedField(value: newPassword, rules: [.password("reset.validation.passwordInvalid")]),
                .confirmation: ValidatedField(value: confirmation, rules: [
                    .required("security.confirm.required"),
                    ValidationRule(message: "security.confirm.mismatch", validate: { $0 == self.newPassword })
                ])
            ]
            blocked = tokenExpired || token == nil
        case .complete:
            fields = [:]
            blocked = true
        }
        return FormState(fields: fields, isSubmitting: isLoading, isBlocked: blocked)
    }

    func refreshTime() { now = clock() }

    func submit() async {
        refreshTime()
        guard form.canSubmit else { return }
        switch step {
        case .currentPassword: await requestCode()
        case .code: await verifyCode()
        case .newPassword: await savePassword()
        case .complete: break
        }
    }

    func resend() async {
        refreshTime()
        guard canResend else { return }
        await requestCode()
    }

    func restart() {
        guard !isLoading else { return }
        currentPassword = ""
        code = ""
        newPassword = ""
        confirmation = ""
        token = nil
        codeDeadline = nil
        resendDeadline = nil
        tokenDeadline = nil
        state = .idle
        step = .currentPassword
    }

    private func remaining(_ deadline: Date?) -> Int {
        guard let deadline else { return 0 }
        return max(0, Int(ceil(deadline.timeIntervalSince(now))))
    }

    private func requestCode() async {
        state = .loading
        do {
            let result = try await service.requestPasswordChange(currentPassword: currentPassword)
            refreshTime()
            codeDeadline = now.addingTimeInterval(TimeInterval(max(0, result.expiresInSeconds)))
            resendDeadline = now.addingTimeInterval(TimeInterval(max(0, result.resendAvailableInSeconds)))
            code = ""
            step = .code
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func verifyCode() async {
        state = .loading
        do {
            let result = try await service.verifyPasswordChange(code: code)
            guard !result.changePasswordToken.isEmpty else { throw NetworkError.invalidResponse }
            refreshTime()
            token = result.changePasswordToken
            tokenDeadline = now.addingTimeInterval(600)
            currentPassword = ""
            code = ""
            step = .newPassword
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func savePassword() async {
        guard let token else { return }
        state = .loading
        do {
            try await service.changePassword(token: token, newPassword: newPassword)
            self.token = nil
            newPassword = ""
            confirmation = ""
            step = .complete
            state = .success
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
