//
//  LoginViewModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation
import Observation

@MainActor
@Observable

final class LoginViewModel {
    private let authService: AuthServiceProtocol
    var state: LoginViewState = .idle

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    func login(email: String, password: String) async {
        state = .loading
        do {
            let request = LoginRequest(email: email, password: password)
            _ = try await authService.login(request: request)

            state = .success
        } catch {
            state = .error(error.localizedDescription)
        }

    }

}
