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
    var state: RegisterViewState = .idle
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    func register(
        lastName: String,
        firstName: String,
        email: String,
        password: String
    ) async {
        state = .loading

        do {
            let request = RegisterRequest(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
            _ = try await authService.register(request: request)

            state = .success
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
