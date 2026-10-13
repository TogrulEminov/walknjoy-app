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

    private var form: FormState<AuthField> {
        AuthForms.login(email: email, password: password, isSubmitting: isLoading)
    }

    private var isLoading: Bool {
        loginVM.state == .loading
    }
    private var isLoginSuccessful: Bool {
        if case .success = loginVM.state {
            return true
        }

        return false
    }



    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            BackgroundDecoration().ignoresSafeArea()
            loginContent
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
                if case .error(let message) = loginVM.state {
                    Text(message).font(.caption).foregroundStyle(Color.errorColor)
                }
                Spacer().frame(height: 14)
                forgotPassword
                Spacer().frame(height: 38)
                loginButton
                #if DEBUG
                Button {
                    appState.enterDemo()
                } label: {
                    Label("Demo ilə daxil ol", systemImage: "play.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.titleText)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.borderColor, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .padding(.top, 12)
                Text("İnternet tələb etmir. Nümunə məlumatlarla sınaq rejimi.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                #endif
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
        AuthHeader(title: "login.title", description: "login.description")
    }
}
extension LoginView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppTextField(
                text: $email,
                placeholder: "input.email",
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalizationType: .none
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .fieldValidation(form[.email])

            AppPasswordField(
                text: $password,
                placeholder: "input.password"
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .fieldValidation(form[.password])

        }
    }
}
extension LoginView {
    private var registerSection: some View {
        HStack(spacing: 5) {
            Text("login.noAccount")
            NavigationLink(value: AuthRoute.register) {
                Text("login.register").fontWeight(.semibold).foregroundStyle(
                    Color.titleText
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
                ).foregroundStyle(Color.titleText)
            }

        }
    }
}

extension LoginView {
    private var loginButton: some View {
        SubmitButton(
            title: "login.button",
            icon: "arrow.right",
            form: form
        ) {
            submit()
        }
    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
//MARK:FUNCTIONS
extension LoginView {
    private func submit() {
        guard form.canSubmit else {
            return
        }
        Task {
            await loginVM.login(email: email, password: password)
        }
    }
}
