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

    @State private var otpVM = OtpViewModel()

    @State private var code = ""

    @State private var otpRemainingSeconds: Int
    @State private var resendRemainingSeconds: Int

    // Timer-ləri resend-dən sonra restart etmək üçün
    @State private var otpTimerID = UUID()
    @State private var resendTimerID = UUID()

    // MARK: - Init

    init(
        email: String,
        expireTime: Int,
        resendAvailableTime: Int
    ) {
        self.email = email
        self.expireTime = expireTime
        self.resendAvailableTime = resendAvailableTime

        _otpRemainingSeconds = State(
            initialValue: expireTime
        )

        _resendRemainingSeconds = State(
            initialValue: resendAvailableTime
        )
    }

    // MARK: - Computed Properties

    private var isCodeComplete: Bool {
        code.count == 6
    }

    private var isOtpExpired: Bool {
        otpRemainingSeconds <= 0
    }

    private var isLoading: Bool {
        if case .loading = otpVM.state {
            return true
        }

        return false
    }

    private var formattedExpireTime: String {
        formatTime(otpRemainingSeconds)
    }

    private var formattedResendTime: String {
        formatTime(resendRemainingSeconds)
    }

    private var canVerify: Bool {
        isCodeComplete &&
        !isOtpExpired &&
        !isLoading
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            BackgroundDecoration()
                .ignoresSafeArea()

            contentView
        }
        .task(id: otpTimerID) {
            await startOtpTimer()
        }
        .task(id: resendTimerID) {
            await startResendTimer()
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
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("otp.title")
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    Color.primary
                )

            Text("otp.description")
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.primary.opacity(0.45)
                )
                .lineSpacing(3)
        }
    }
}

// MARK: - Email

extension OtpView {

    private var emailSection: some View {
        HStack(spacing: 5) {
            Text("otp.sentTo")
                .foregroundStyle(
                    Color.primary.opacity(0.45)
                )

            Text(email)
                .fontWeight(.semibold)
                .foregroundStyle(
                    Color.primary
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
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .frame(height: 56)
        .disabled(
            isLoading ||
            isOtpExpired
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
                .foregroundStyle(.red)
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
                    .foregroundStyle(.red)

            } else {

                Text("otp.expiresIn")
                    .foregroundStyle(
                        Color.primary.opacity(0.45)
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
                        Color.primary
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
                        Color.primary.opacity(0.45)
                    )

                Button {
                    resendCode()
                } label: {
                    Text("otp.resend")
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            resendRemainingSeconds == 0
                                ? Color.primary
                                : Color.primary.opacity(0.35)
                        )
                }
                .disabled(
                    resendRemainingSeconds > 0 ||
                    isLoading
                )
                Spacer()
                
            }

            if resendRemainingSeconds > 0 {
                HStack(spacing: 5) {

                    Text("otp.resendAvailableIn")
                        .foregroundStyle(
                            Color.primary.opacity(0.45)
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
                            Color.primary.opacity(0.45)
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
        Button {
            verifyCode()
        } label: {

            HStack(spacing: 12) {

                if isLoading {
                    ProgressView()
                        .tint(Color.primary)
                } else {
                    Text("otp.button")

                    Image(
                        systemName: "arrow.right"
                    )
                }
            }
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Color.primaryYellow.opacity(
                    canVerify ? 1 : 0.45
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canVerify)
    }
}

// MARK: - Actions

extension OtpView {

    private func verifyCode() {
        guard canVerify else {
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
            resendRemainingSeconds == 0,
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

        otpRemainingSeconds =
            expiresInSeconds

        resendRemainingSeconds =
            resendAvailableInSeconds

        // .task(id:) yenidən işə düşəcək
        otpTimerID = UUID()
        resendTimerID = UUID()
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

// MARK: - Timers

extension OtpView {

    private func startOtpTimer() async {
        while otpRemainingSeconds > 0 {

            do {
                try await Task.sleep(
                    for: .seconds(1)
                )
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            guard otpRemainingSeconds > 0 else {
                return
            }

            otpRemainingSeconds -= 1
        }
    }

    private func startResendTimer() async {
        while resendRemainingSeconds > 0 {

            do {
                try await Task.sleep(
                    for: .seconds(1)
                )
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            guard resendRemainingSeconds > 0 else {
                return
            }

            resendRemainingSeconds -= 1
        }
    }
}

// MARK: - Helpers

extension OtpView {

    private func formatTime(
        _ seconds: Int
    ) -> String {
        String(
            format: "%02d:%02d",
            seconds / 60,
            seconds % 60
        )
    }

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
