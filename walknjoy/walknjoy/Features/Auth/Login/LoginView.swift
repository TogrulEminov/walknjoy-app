//
//  LoginView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

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
                    Spacer().frame(height: 14)
                    forgotPassword
                    Spacer().frame(height: 38)
                    loginButton
                    Spacer()
                        .frame(height: 36)
                    registerSection
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
extension LoginView {
    private var logoView: some View {
        Image("logo-colorfull").resizable().scaledToFit().frame(width: 150)
    }
}

extension LoginView {
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("login.title").font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primaryBlue)
            Text("login.description").font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.primaryBlue.opacity(0.45)).lineSpacing(3)
        }
    }
}
extension LoginView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
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
extension LoginView {
    private var registerSection: some View {
        HStack(spacing: 5) {
            Text("login.noAccount")
            NavigationLink(value: AuthRoute.register) {
                Text("login.register").fontWeight(.semibold).foregroundStyle(
                    Color.primaryBlue
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}
extension LoginView {
    private var forgotPassword: some View {
        HStack {
            Spacer()
            NavigationLink(value: AuthRoute.forgotPassword) {
                Text("login.forgotPassword").font(
                    .system(size: 14, weight: .semibold)
                ).foregroundStyle(Color.primaryBlue)
            }

        }
    }
}
extension LoginView {
    private var loginButton: some View {
        Button {
            print("hello")
        } label: {
            HStack {
                Text("login.button")
                Image(systemName: "arrow.right")
            }.font(.system(size: 16, weight: .semibold)).foregroundStyle(
                Color.primaryBlue
            ).frame(maxWidth: .infinity).frame(height: 56).background(
                Color.primaryYellow
            ).clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)

    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
