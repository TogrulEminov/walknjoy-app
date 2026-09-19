//
//  OtpView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//

import SwiftUI

struct OtpView: View {

    let email: String

    @State private var code = ""
    @State private var remainingSeconds = 60

    private var isCodeComplete: Bool {
        code.count == 6
    }

    private var formattedTime: String {
        String(
            format: "%02d:%02d",
            remainingSeconds / 60,
            remainingSeconds % 60
        )
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            LoginBackgroundDecoration()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    logoView

                    Spacer()
                        .frame(height: 100)

                    headers

                    Spacer()
                        .frame(height: 24)

                    emailSection

                    Spacer()
                        .frame(height: 28)

                    otpInput

                    Spacer()
                        .frame(height: 28)

                    resendSection

                    Spacer()
                        .frame(height: 38)

                    continueButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .task {
            await startTimer()
        }
    }
}
extension OtpView {

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("otp.title")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primaryBlue)

            Text("otp.description")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    Color.primaryBlue.opacity(0.45)
                )
                .lineSpacing(3)
        }
    }
}
extension OtpView {

    private var logoView: some View {
        Image("logo-colorfull")
            .resizable()
            .scaledToFit()
            .frame(width: 150)
    }
}
extension OtpView {

    private var headers: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("otp.title")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primaryBlue)

            Text("otp.description")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    Color.primaryBlue.opacity(0.45)
                )
                .lineSpacing(3)
        }
    }
}
extension OtpView {

    private var emailSection: some View {
        HStack(spacing: 5) {

            Text("otp.sentTo")
                .foregroundStyle(
                    Color.primaryBlue.opacity(0.45)
                )

            Text(email)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryBlue)

            Spacer()
        }
        .font(.system(size: 14))
    }
}
extension OtpView {
    private var otpInput: some View {
        OTPRepresentable(
            code: $code,
            digitCount: 6
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 56)
    }
}
extension OtpView {

    private var resendSection: some View {
        VStack(spacing: 10) {

            HStack(alignment: .top, spacing: 5) {

                Text("otp.didNotReceive")
                    .foregroundStyle(
                        Color.primaryBlue.opacity(0.45)
                    )

                Button {
                    resendCode()
                } label: {
                    Text("otp.resend")
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            remainingSeconds == 0
                                ? Color.primaryBlue
                                : Color.primaryBlue.opacity(0.35)
                        )
                }
                .disabled(remainingSeconds > 0)
            }

            if remainingSeconds > 0 {
                Text(formattedTime)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        Color.primaryBlue.opacity(0.45)
                    )
            }
        }
        .font(.system(size: 14))
        .frame(maxWidth: .infinity)
    }
}
extension OtpView {

    private var continueButton: some View {
        Button {
            verifyCode()
        } label: {
            HStack(spacing: 12) {

                Text("otp.button")

                Image(systemName: "arrow.right")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.primaryBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Color.primaryYellow.opacity(
                    isCodeComplete ? 1 : 0.45
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isCodeComplete)
    }
}
extension OtpView {

    private func startTimer() async {
        while remainingSeconds > 0 {

            try? await Task.sleep(for: .seconds(1))

            guard !Task.isCancelled else {
                return
            }

            remainingSeconds -= 1
        }
    }

    private func resendCode() {
        guard remainingSeconds == 0 else {
            return
        }

        code = ""
        remainingSeconds = 60

    }

    private func verifyCode() {
        guard isCodeComplete else {
            return
        }

        print("OTP:", code)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#Preview {
    OtpView(email: "togrul@example.com")
}
