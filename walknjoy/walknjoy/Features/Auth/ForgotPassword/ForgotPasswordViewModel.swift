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
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    func forgotPassowrd(email: String) async {
        state = .loading
        do {
            let request = ForgotPasswordRequest(email: email)

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
