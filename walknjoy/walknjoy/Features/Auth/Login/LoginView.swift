//
//  LoginView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var loginVM: LoginViewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private var isLoginSuccessful: Bool {
        if case .success = loginVM.state {
            return true
        }

        return false
    }

    private func validateForm() -> Bool {

        if !FormValdation.isValidEmail(email) {
            validationMessage = String(
                localized: "login.validation.email"
            )
            return false
        }

        if !FormValdation.isValidPassword(password) {
            validationMessage = String(
                localized: "login.validation.password"
            )
            return false
        }

        return true
    }

    var body: some View {
        ZStack {
            BackgroundDecoration().ignoresSafeArea()
            loginContent
        }.alert("login.validation.title", isPresented: $showValidationAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
        .onChange(of: isLoginSuccessful) { _, isSuccessfully in
            if isSuccessfully {
                appState.finishAuthentication()
            }
        }
    }
}
extension LoginView {
    private var loginContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                LogoView()
                Spacer().frame(height: 100)
                header
                Spacer().frame(height: 32)
                inputFields
                Spacer().frame(height: 14)
                forgotPassword
                Spacer().frame(height: 38)
                loginButton
                Spacer()
                    .frame(height: 36)
                registerSection
            }.padding(.horizontal, 24).padding(.top, 20).padding(
                .bottom,
                30
            )
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}

extension LoginView {
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("login.title").font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primary)
            Text("login.description").font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.primary.opacity(0.45)).lineSpacing(3)
        }
    }
}
extension LoginView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            InputFieldRepresentable(
                text: $email,
                placeholder: String(
                    localized: "input.email"
                ),
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalizationType: .none
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)

            PasswordFieldRepresentable(
                text: $password,
                placeHolder: String(
                    localized: "input.password"
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)

        }
    }
}
extension LoginView {
    private var registerSection: some View {
        HStack(spacing: 5) {
            Text("login.noAccount")
            NavigationLink(value: AuthRoute.register) {
                Text("login.register").fontWeight(.semibold).foregroundStyle(
                    Color.primary
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}
extension LoginView {
    private var forgotPassword: some View {
        HStack {
            Spacer()
            NavigationLink(value: AuthRoute.forgotPassword) {
                Text("login.forgotPassword").font(
                    .system(size: 14, weight: .semibold)
                ).foregroundStyle(Color.primary)
            }

        }
    }
}
extension LoginView {
    private var loginButton: some View {
        Button {
            guard validateForm() else {
                showValidationAlert = true
                return
            }
            Task {
                await loginVM.login(email: email, password: password)
            }
        } label: {
            HStack {
                Text("login.button")
                Image(systemName: "arrow.right")
            }.font(.system(size: 16, weight: .semibold)).foregroundStyle(
                Color.primary
            ).frame(maxWidth: .infinity).frame(height: 56).background(
                Color.primaryYellow
            ).clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)

    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
