import SwiftUI

struct AuthView: View {

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {

            LoginView()
                .navigationDestination(
                    for: AuthRoute.self
                ) { route in
                    authDestination(
                        with: route
                    )
                }
        }
        .environment(
            \.authNavigationPath,
            $path
        )
    }
}

extension AuthView {

    @ViewBuilder
    private func authDestination(
        with route: AuthRoute
    ) -> some View {

        switch route {

        case .login:
            LoginView()

        case .register:
            RegisterView()

        case .forgotPassword:
            ForgotPasswordView()

        case .otp(
            let email,
            let expireTime,
            let resendAvailableTime
        ):
            OtpView(
                email: email,
                expireTime: expireTime,
                resendAvailableTime: resendAvailableTime
            )

        case .resetPassword(let resetToken):
            ResetPasswordView(
                onSuccess: {
                    path = NavigationPath()
                },
                resetToken: resetToken,

            )
        }
    }
}
