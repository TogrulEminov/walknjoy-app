//
//  ForgotPasswordView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//

import SwiftUI

struct ForgotPasswordView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - ViewModel

    @State private var forgotPasswordVM = ForgotPasswordViewModel()

    // MARK: - Form State

    @State private var email = ""

    // MARK: - Validation State

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    // MARK: - Navigation State

    @State private var navigateToOtp = false

    @State private var expiresInSeconds = 0
    @State private var resendAvailableInSeconds = 0

    // MARK: - Computed Properties

    private var isLoading: Bool {
        if case .loading = forgotPasswordVM.state {
            return true
        }

        return false
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            BackgroundDecoration()
                .ignoresSafeArea()

            contentView
        }
        .alert(
            "forgot.validation.title",
            isPresented: $showValidationAlert
        ) {
            Button(
                "common.ok",
                role: .cancel
            ) {}
        } message: {
            Text(validationMessage)
        }
        .navigationDestination(
            isPresented: $navigateToOtp
        ) {
            OtpView(
                email: email,
                expireTime: expiresInSeconds,
                resendAvailableTime: resendAvailableInSeconds
            )
        }
        .onChange(
            of: forgotPasswordVM.state
        ) { _, newState in
            handleStateChange(newState)
        }
    }
}

// MARK: - Content

extension ForgotPasswordView {

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
                    .frame(height: 32)

                inputFields

                errorContent

                Spacer()
                    .frame(height: 38)

                customButton

                Spacer()
                    .frame(height: 36)

                loginSection
            }
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

extension ForgotPasswordView {

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("forgot.title")
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )
                .foregroundStyle(Color.primary)

            Text("forgot.description")
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

// MARK: - Input Fields

extension ForgotPasswordView {

    private var inputFields: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {

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
        }
    }
}

// MARK: - Error

extension ForgotPasswordView {

    @ViewBuilder
    private var errorContent: some View {

        if case .error(let message) = forgotPasswordVM.state {

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
                .padding(.top, 12)
        }
    }
}

// MARK: - Login Section

extension ForgotPasswordView {

    private var loginSection: some View {
        HStack(spacing: 5) {

            Text("forgot.remember")

            Button {
                dismiss()
            } label: {

                Text("login.button")
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        Color.primary
                    )
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 14))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Button

extension ForgotPasswordView {

    private var customButton: some View {
        Button {

            submit()

        } label: {

            HStack(spacing: 12) {

                if isLoading {

                    ProgressView()
                        .tint(Color.primary)

                } else {

                    Text("forgot.button")

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
                    isLoading ? 0.6 : 1
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Actions

extension ForgotPasswordView {

    private func submit() {

        guard validateForm() else {
            showValidationAlert = true
            return
        }

        dismissKeyboard()

        Task {
            await forgotPasswordVM.forgotPassowrd(
                email: email
            )
        }
    }

    private func validateForm() -> Bool {

        if !FormValdation.isValidEmail(email) {

            validationMessage = String(
                localized: "forgot.validation.email"
            )

            return false
        }

        return true
    }
}

// MARK: - State Handler

extension ForgotPasswordView {

    private func handleStateChange(
        _ state: ForgotPasswordState
    ) {

        switch state {

        case .idle,
            .loading,
            .error:
            break

        case .success(
            let expiresInSeconds,
            let resendAvailableInSeconds
        ):

            self.expiresInSeconds =
                expiresInSeconds

            self.resendAvailableInSeconds =
                resendAvailableInSeconds

            navigateToOtp = true
        }
    }
}

// MARK: - Helpers

extension ForgotPasswordView {

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
        ForgotPasswordView()
    }
}
