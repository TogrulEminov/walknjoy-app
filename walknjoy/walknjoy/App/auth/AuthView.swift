//
//  AuthView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 18.09.26.
//

import SwiftUI

struct AuthView: View {

    var body: some View {
        Text("salam")
    }
}

extension AuthView {
    @ViewBuilder
    private func authDestination(with route: AuthRoute) -> some View {
        switch route {
        case .login: LoginView()
        case .register: RegisterView()
        case .forgotPassword:ForgotPasswordView()
        case .resetPassword:ResetPasswordView()
        }
    }
}
