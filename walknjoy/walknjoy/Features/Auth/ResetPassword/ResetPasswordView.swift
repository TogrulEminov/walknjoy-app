import SwiftUI

struct ResetPasswordView: View {
    let onSuccess: () -> Void

    var resetToken: String
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    @State private var viewModel: ResetPasswordViewModel =
        ResetPasswordViewModel()

    @State private var newPassword = ""

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }
    var body: some View {
        ZStack {
            BackgroundDecoration().ignoresSafeArea()
            contentView
        }
        .alert("reset.validation.title", isPresented: $showValidationAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }.onChange(of: viewModel.state) { _, newValue in
            handleStateChange(newValue)
        }

    }
}
extension ResetPasswordView {

    private func submit() {

        guard validateForm() else {
            showValidationAlert = true
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

    private func validateForm() -> Bool {

        guard !newPassword.isEmpty else {
            validationMessage = String(
                localized: "reset.validation.passwordRequired"
            )
            return false
        }

        guard FormValdation.isValidPassword(newPassword) else {
            validationMessage = String(
                localized: "reset.validation.passwordInvalid"
            )
            return false
        }

        return true
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
        _ state: ResetPasswordState
    ) {
        print("RESET STATE CHANGED:", state)

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
        VStack(alignment: .leading, spacing: 10) {
            Text("reset.title").font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primary)
            Text("reset.description").font(
                .system(size: 16, weight: .medium)
            )
            .foregroundStyle(Color.primary.opacity(0.45)).lineSpacing(3)
        }
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

        }
    }
}
extension ResetPasswordView {
    private var loginSection: some View {
        HStack(spacing: 5) {
            Text("login.back")
            NavigationLink(value: AuthRoute.login) {
                Text("login.button").fontWeight(.semibold).foregroundStyle(
                    Color.primary
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}

extension ResetPasswordView {
    private var customButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                Text("reset.button")
                Image(systemName: "arrow.right")
            }.font(.system(size: 16, weight: .semibold)).foregroundStyle(
                Color.primary
            ).frame(maxWidth: .infinity).frame(height: 56).background(
                Color.primaryYellow
            ).clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)

    }
}
struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(onSuccess: {}, resetToken: "token")
    }
}
