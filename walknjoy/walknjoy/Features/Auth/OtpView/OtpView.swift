//
//  OtpView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//

import SwiftUI

struct OtpView: View {

    // MARK: - Environment

    @Environment(\.authNavigationPath)
    private var path

    // MARK: - Properties

    let email: String
    let expireTime: Int
    let resendAvailableTime: Int

    // MARK: - State

    @State private var otpVM: OtpViewModel

    @State private var code = ""

    // MARK: - Init

    init(
        email: String,
        expireTime: Int,
        resendAvailableTime: Int
    ) {
        self.email = email
        self.expireTime = expireTime
        self.resendAvailableTime = resendAvailableTime

        _otpVM = State(initialValue: OtpViewModel(expireTime: expireTime, resendAvailableTime: resendAvailableTime))
    }

    // MARK: - Computed Properties



    private var isOtpExpired: Bool {
        otpVM.isOtpExpired
    }

    private var isLoading: Bool {
        if case .loading = otpVM.state {
            return true
        }

        return false
    }

    private var formattedExpireTime: String {
        otpVM.formattedExpireTime
    }

    private var formattedResendTime: String {
        otpVM.formattedResendTime
    }

    private var form: FormState<AuthField> {
        AuthForms.otp(code: code, isSubmitting: isLoading, isBlocked: isOtpExpired)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            BackgroundDecoration()
                .ignoresSafeArea()

            contentView
        }
        .task(id: otpVM.otpTimerID) {
            await otpVM.startOtpTimer()
        }
        .task(id: otpVM.resendTimerID) {
            await otpVM.startResendTimer()
        }
        .onChange(of: otpVM.state) { _, newState in
            handleStateChange(newState)
        }
    }
}

// MARK: - Content

extension OtpView {

    private var contentView: some View {
        ScrollView(
            .vertical,
            showsIndicators: false
        ) {
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                LogoView()

                Spacer()
                    .frame(height: 100)

                header

                Spacer()
                    .frame(height: 24)

                emailSection

                Spacer()
                    .frame(height: 28)

                otpInput

                errorContent

                Spacer()
                    .frame(height: 14)

                expirationSection

                Spacer()
                    .frame(height: 28)

                resendSection

                Spacer()
                    .frame(height: 38)

                continueButton
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }
}

// MARK: - Header

extension OtpView {
    private var header: some View {
        AuthHeader(title: "otp.title", description: "otp.description")
    }
}

// MARK: - Email

extension OtpView {

    private var emailSection: some View {
        HStack(spacing: 5) {
            Text("otp.sentTo")
                .foregroundStyle(
                    Color.titleText.opacity(0.45)
                )

            Text(email)
                .fontWeight(.semibold)
                .foregroundStyle(
                    Color.titleText
                )

            Spacer()
        }
        .font(.system(size: 14))
    }
}

// MARK: - OTP Input

extension OtpView {

    private var otpInput: some View {
        OTPRepresentable(
            code: $code,
            digitCount: 6
        )
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .fieldValidation(form[.code])
        .disabled(
            isLoading || isOtpExpired
        )
    }
}

// MARK: - Error

extension OtpView {

    @ViewBuilder
    private var errorContent: some View {
        if case .error(let message) = otpVM.state {
            Text(message)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(Color.errorColor)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.top, 10)
        }
    }
}

// MARK: - OTP Expiration

extension OtpView {

    private var expirationSection: some View {
        HStack(spacing: 5) {

            if isOtpExpired {

                Text("otp.expired")
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(Color.errorColor)

            } else {

                Text("otp.expiresIn")
                    .foregroundStyle(
                        Color.titleText.opacity(0.45)
                    )

                Text(formattedExpireTime)
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        Color.titleText
                    )
            }
        }
        .font(.system(size: 14))
    }
}

// MARK: - Resend

extension OtpView {

    private var resendSection: some View {
        VStack(spacing: 10) {

            HStack(
                spacing: 5
            ) {
                Text("otp.didNotReceive")
                    .foregroundStyle(
                        Color.titleText.opacity(0.45)
                    )

                Button {
                    resendCode()
                } label: {
                    Text("otp.resend")
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            otpVM.resendRemainingSeconds == 0
                                ? Color.titleText
                                : Color.titleText.opacity(0.35)
                        )
                }
                .disabled(
                    otpVM.resendRemainingSeconds > 0 || isLoading
                )
                Spacer()

            }

            if otpVM.resendRemainingSeconds > 0 {
                HStack(spacing: 5) {

                    Text("otp.resendAvailableIn")
                        .foregroundStyle(
                            Color.titleText.opacity(0.45)
                        )

                    Text(formattedResendTime)
                        .font(
                            .system(
                                size: 15,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(
                            Color.titleText.opacity(0.45)
                        )

                    Spacer()
                }
            }
        }
        .font(.system(size: 14))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Continue Button

extension OtpView {

    private var continueButton: some View {
        SubmitButton(
            title: "otp.button",
            icon: "arrow.right",
            form: form
        ) {
            verifyCode()
        }
    }
}

// MARK: - Actions

extension OtpView {

    private func verifyCode() {
        guard form.canSubmit else {
            return
        }

        dismissKeyboard()

        Task {
            await otpVM.verify(
                email: email,
                code: code
            )
        }
    }

    private func resendCode() {
        guard
            otpVM.resendRemainingSeconds == 0,
            !isLoading
        else {
            return
        }

        dismissKeyboard()

        Task {
            await otpVM.resend(
                email: email
            )
        }
    }
}

// MARK: - State Handler

extension OtpView {

    private func handleStateChange(
        _ state: OtpViewState
    ) {
        switch state {

        case .idle,
            .loading,
            .error:
            break

        case .resendSuccess(
            let expiresInSeconds,
            let resendAvailableInSeconds
        ):
            handleResendSuccess(
                expiresInSeconds: expiresInSeconds,
                resendAvailableInSeconds:
                    resendAvailableInSeconds
            )

        case .success(let token):
            goToResetPassword(
                resetToken: token
            )
        }
    }

    private func handleResendSuccess(
        expiresInSeconds: Int,
        resendAvailableInSeconds: Int
    ) {
        code = ""


    }

    private func goToResetPassword(
        resetToken: String
    ) {
        path.wrappedValue.append(
            AuthRoute.resetPassword(
                resetToken: resetToken
            )
        )
    }
}

// MARK: - Helpers

extension OtpView {

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

// MARK: - Preview

#Preview {
    NavigationStack {
        OtpView(
            email: "togrul@example.com",
            expireTime: 600,
            resendAvailableTime: 60
        )
    }
}
