//
//  RegisterViewModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var state: RequestState = .idle
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService()
    }

    func register(
        lastName: String,
        firstName: String,
        email: String,
        password: String
    ) async {
        guard
            AuthForms.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            ).canSubmit
        else { return }
        if case .loading = state { return }
        state = .loading

        do {
            let request = RegisterRequest(
                firstName: firstName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                lastName: lastName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            _ = try await authService.register(request: request)

            state = .success
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
