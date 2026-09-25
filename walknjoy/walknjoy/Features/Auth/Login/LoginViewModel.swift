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
    var state: RequestState = .idle

    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService()
    }
    func login(email: String, password: String) async {
        guard AuthForms.login(email: email, password: password).canSubmit else { return }
        if case .loading = state { return }
        state = .loading
        do {
            let request = LoginRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            _ = try await authService.login(request: request)

            state = .success
        } catch {
            state = .error(error.localizedDescription)
        }

    }

}
