//
//  ForgotPasswordView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            LoginBackgroundDecoration().ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    logoView
                    Spacer().frame(height: 100)
                    header
                    Spacer().frame(height: 32)
                    inputFields
                    Spacer().frame(height: 38)
                    PasswordRequirementsView(password: password)
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
}

extension ForgotPasswordView {
    private var logoView: some View {
        Image("logo-colorfull").resizable().scaledToFit().frame(width: 150)
    }
}

extension ForgotPasswordView {
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("reset.title").font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primaryBlue)
            Text("reset.description").font(
                .system(size: 16, weight: .medium)
            )
            .foregroundStyle(Color.primaryBlue.opacity(0.45)).lineSpacing(3)
        }
    }
}
extension ForgotPasswordView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            PasswordFieldRepresentable(
                text: $password,
                placeHolder: String(
                    localized: "input.password"
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            PasswordFieldRepresentable(
                text: $confirmPassword,
                placeHolder: String(
                    localized: "input.confirmPassword"
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
    }
}
extension ForgotPasswordView {
    private var loginSection: some View {
        HStack(spacing: 5) {
            Text("login.back")
            NavigationLink(value: AuthRoute.login) {
                Text("login.button").fontWeight(.semibold).foregroundStyle(
                    Color.primaryBlue
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}

extension ForgotPasswordView {
    private var customButton: some View {
        Button {
            print("hello")
        } label: {
            HStack {
                Text("reset.button")
                Image(systemName: "arrow.right")
            }.font(.system(size: 16, weight: .semibold)).foregroundStyle(
                Color.primaryBlue
            ).frame(maxWidth: .infinity).frame(height: 56).background(
                Color.primaryYellow
            ).clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)

    }
}
struct ForgotPassword_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
