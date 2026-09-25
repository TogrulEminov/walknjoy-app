import SwiftUI

struct ResetPasswordView: View {
    let onSuccess: () -> Void

    var resetToken: String

    @State private var viewModel: ResetPasswordViewModel =
        ResetPasswordViewModel()

    @State private var newPassword = ""

    private var form: FormState<AuthField> {
        AuthForms.resetPassword(password: newPassword, isSubmitting: isLoading, isBlocked: resetToken.isEmpty)
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            BackgroundDecoration().ignoresSafeArea()
            contentView
        }
        .onChange(of: viewModel.state) { _, newValue in
            handleStateChange(newValue)
        }

    }
}
extension ResetPasswordView {

    private func submit() {

        guard form.canSubmit else {
            return
        }

        dismissKeyboard()

        Task {
            await viewModel.resetPassword(
                password: newPassword,
                resetToken: resetToken
            )
        }
    }


}
extension ResetPasswordView {

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
extension ResetPasswordView {

    private func handleStateChange(
        _ state: RequestState
    ) {

        switch state {
        case .idle,
            .loading,
            .error:
            break

        case .success:
            dismissKeyboard()
            onSuccess()
        }
    }

}
extension ResetPasswordView {
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                LogoView()
                Spacer().frame(height: 100)
                header
                Spacer().frame(height: 32)
                inputFields
                if case .error(let message) = viewModel.state {
                    Text(message).font(.caption).foregroundStyle(Color.errorColor)
                }
                Spacer().frame(height: 38)
                PasswordRequirementsView(password: newPassword)
                Spacer().frame(height: 38)
                customButton
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

extension ResetPasswordView {
    private var header: some View {
        AuthHeader(title: "reset.title", description: "reset.description")
    }
}
extension ResetPasswordView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            PasswordFieldRepresentable(
                text: $newPassword,
                placeHolder: String(
                    localized: "input.password"
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .fieldValidation(form[.password])

        }
    }
}
extension ResetPasswordView {
    private var loginSection: some View {
        HStack(spacing: 5) {
            Text("login.back")
            NavigationLink(value: AuthRoute.login) {
                Text("login.button").fontWeight(.semibold).foregroundStyle(
                    Color.titleText
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}

extension ResetPasswordView {
    private var customButton: some View {
        SubmitButton(title: "reset.button", icon: "arrow.right", form: form) {
            submit()
        }
    }
}
struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(onSuccess: {}, resetToken: "token")
    }
}
