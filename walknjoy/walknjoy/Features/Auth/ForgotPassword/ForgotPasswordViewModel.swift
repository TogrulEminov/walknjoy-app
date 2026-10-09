//
//  ForgotPasswordViewModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ForgotPasswordViewModel {
    private let authService: AuthServiceProtocol
    var state: ForgotPasswordState = .idle
    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService()
    }

    func forgotPassowrd(email: String) async {
        guard AuthForms.forgotPassword(email: email).canSubmit else { return }
        if case .loading = state { return }
        state = .loading
        do {
            let request = ForgotPasswordRequest(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            let response = try await authService.forgotPassword(
                request: request
            )

            state = .success(
                expiresInSeconds:
                    response.expiresInSeconds,
                resendAvailableInSeconds:
                    response.resendAvailableInSeconds
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
