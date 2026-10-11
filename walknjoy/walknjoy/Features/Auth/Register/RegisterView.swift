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


    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""

    private var form: FormState<AuthField> {
        AuthForms.register(firstName: firstName, lastName: lastName, email: email, password: password, isSubmitting: isLoading)
    }

    private var isLoading: Bool {
        if case .loading = registerVM.state {
            return true
        }

        return false
    }


    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            BackgroundDecoration().ignoresSafeArea()

            switch registerVM.state {
            case .success: successContent
            default: registerContent
            }
        }
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
    }
}
extension RegisterView {

    @ViewBuilder
    private var errorContent: some View {
        if case .error(let message) = registerVM.state {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.errorColor)
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
        AuthHeader(title: "register.title", description: "register.description")
    }
}
extension RegisterView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppTextField(
                text: $firstName,
                placeholder: "input.firstName",
                icon: "person",
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .fieldValidation(form[.firstName])
            AppTextField(
                text: $lastName,
                placeholder: "input.lastName",
                icon: "person",
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .fieldValidation(form[.lastName])

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
extension RegisterView {
    private var loginSection: some View {
        HStack(spacing: 5) {
            Text("register.loginText")
            NavigationLink(value: AuthRoute.login) {
                Text("register.login").fontWeight(.semibold).foregroundStyle(
                    Color.titleText
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}

extension RegisterView {
    private var registerButton: some View {
        SubmitButton(
            title: "register.button",
            icon: "arrow.right",
            form: form,
        ) {
            submit()
        }

    }
}
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}

extension RegisterView {
    private func submit() {
        guard form.canSubmit else {
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
    }
}
