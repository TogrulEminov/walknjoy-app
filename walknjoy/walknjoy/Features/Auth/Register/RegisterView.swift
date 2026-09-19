//
//  RegisterView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
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
}
extension RegisterView {
    private var logoView: some View {
        Image("logo-colorfull").resizable().scaledToFit().frame(width: 150)
    }
}

extension RegisterView {
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("register.title").font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.primaryBlue)
            Text("register.description").font(
                .system(size: 16, weight: .medium)
            )
            .foregroundStyle(Color.primaryBlue.opacity(0.45)).lineSpacing(3)
        }
    }
}
extension RegisterView {
    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            InputFieldRepresentable(
                text: $firstName,
                placeholder: String(
                    localized: "input.firstName"
                ),
                icon: "person",
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            InputFieldRepresentable(
                text: $lastName,
                placeholder: String(
                    localized: "input.lastName"
                ),
                icon: "person",
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)

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
extension RegisterView {
    private var loginSection: some View {
        HStack(spacing: 5) {
            Text("register.loginText")
            NavigationLink(value: AuthRoute.login) {
                Text("register.login").fontWeight(.semibold).foregroundStyle(
                    Color.primaryBlue
                )
            }

        }.font(.system(size: 14)).frame(maxWidth: .infinity)
    }
}

extension RegisterView {
    private var registerButton: some View {
        Button {
            print("hello")
        } label: {
            HStack {
                Text("register.button")
                Image(systemName: "arrow.right")
            }.font(.system(size: 16, weight: .semibold)).foregroundStyle(
                Color.primaryBlue
            ).frame(maxWidth: .infinity).frame(height: 56).background(
                Color.primaryYellow
            ).clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)

    }
}
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
