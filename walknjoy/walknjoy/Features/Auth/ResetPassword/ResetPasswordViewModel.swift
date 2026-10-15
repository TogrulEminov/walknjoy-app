//
//  ResetPasswordViewModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ResetPasswordViewModel {
    private let authService: AuthServiceProtocol
    var state: RequestState = .idle
    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService()
    }

    func resetPassword(password: String, resetToken: String) async {
        guard
            AuthForms.resetPassword(
                password: password,
                isBlocked: resetToken.isEmpty
            ).canSubmit
        else { return }
        if case .loading = state { return }
        state = .loading

        do {
            let request = ResetPasswordRequest(
                resetToken: resetToken,
                newPassword: password
            )
            _ = try await authService.resetPassword(request: request)
            state = .success
        } catch is CancellationError {
            return
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
