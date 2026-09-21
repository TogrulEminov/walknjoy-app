//
//  RegisterView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var registerVM = RegisterViewModel()

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    private func validateForm() -> Bool {

        if !FormValdation.isNotEmpty(firstName) {
            validationMessage = String(
                localized: "register.validation.firstName"
            )
            return false
        }

        if !FormValdation.isNotEmpty(lastName) {
            validationMessage = String(
                localized: "register.validation.lastName"
            )
            return false
        }

        if !FormValdation.isValidEmail(email) {
            validationMessage = String(
                localized: "register.validation.email"
            )
            return false
        }

        if !FormValdation.isValidPassword(password) {
            validationMessage = String(
                localized: "register.validation.password"
            )
            return false
        }

        return true
    }

    var body: some View {
        ZStack {
           
            BackgroundDecoration().ignoresSafeArea()

            switch registerVM.state {
            case .success: successContent
            default: registerContent
            }
        }.alert(
            "register.validation.title",
            isPresented: $showValidationAlert
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }
}
extension RegisterView {

    private var isLoading: Bool {
        if case .loading = registerVM.state {
            return true
        }

        return false
    }
}
extension RegisterView {

    private var successContent: some View {
        SuccessStateView(
            title: "register.success.title",
            message: "register.success.message",
            buttonTitle: "register.success.button"
        ) {
            dismiss()
        }
        .padding(.horizontal, 24)
    }
}
extension RegisterView {

    @ViewBuilder
    private var errorContent: some View {
        if case .error(let message) = registerVM.state {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.red)
                .padding(.top, 12)
        }
    }
}

extension RegisterView {
    private var registerContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                LogoView()
                Spacer().frame(height: 100)
                header
                Spacer().frame(height: 32)
                inputFields
                errorContent
                Spacer().frame(height: 38)

                registerButton
                Spacer()
                    .frame(height: 36)
                loginSection
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
 

extension RegisterView {
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("register.title").font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primary)
            Text("register.description").font(
                .system(size: 16, weight: .medium)
            )
            .foregroundStyle(Color.primary.opacity(0.45)).lineSpacing(3)
        }
    }
}
extension RegisterView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            InputFieldRepresentable(
                text: $firstName,
                placeholder: String(
                    localized: "input.firstName"
                ),
                icon: "person",
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            InputFieldRepresentable(
                text: $lastName,
                placeholder: String(
                    localized: "input.lastName"
                ),
                icon: "person",
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)

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
extension RegisterView {
    private var loginSection: some View {
        HStack(spacing: 5) {
            Text("register.loginText")
            NavigationLink(value: AuthRoute.login) {
                Text("register.login").fontWeight(.semibold).foregroundStyle(
                    Color.primary
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}

extension RegisterView {
    private var registerButton: some View {
        Button {

            guard validateForm() else {
                showValidationAlert = true
                return
            }

            Task {
                await registerVM.register(
                    lastName: lastName,
                    firstName: firstName,
                    email: email,
                    password: password
                )

            }
        } label: {
            HStack {
                Text("register.button")
                Image(systemName: "arrow.right")
            }.font(.system(size: 16, weight: .semibold)).foregroundStyle(
                Color.primary
            ).frame(maxWidth: .infinity).frame(height: 56).background(
                Color.primaryYellow
            ).clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)

    }
}
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
