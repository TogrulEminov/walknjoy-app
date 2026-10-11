import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = SecurityViewModel()

    var body: some View {
        Form {
            Section {
                Label("security.changePassword", systemImage: "lock.shield")
                    .font(.headline)
                    .foregroundStyle(Color.titleText)
                    .padding(.vertical, 8)
                Text("security.description")
                    .font(.subheadline)
                    .foregroundStyle(Color.descriptionText)
            }
            .listRowBackground(Color.surfaceBackground)

            if model.step == .complete {
                Section {
                    Label("security.success", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.titleText)
                    Text("security.sessions").font(.footnote).foregroundStyle(Color.descriptionText)
                    Button("common.ok") { dismiss() }
                }
                .listRowBackground(Color.surfaceBackground)
            } else {
                Section {
                    fields
                } header: {
                    Text(stepTitle)
                }
                .listRowBackground(Color.surfaceBackground)
                .disabled(model.isLoading)

                Section {
                    if case .error(let message) = model.state {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(Color.errorColor)
                    }

                    if model.step == .code {
                        if model.codeSeconds > 0 {
                            Text(String(format: String(localized: "security.code.remainingFormat"), model.codeSeconds))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.descriptionText)
                        } else {
                            Text("security.code.expired").foregroundStyle(Color.errorColor)
                        }
                        Button {
                            Task { await model.resend() }
                        } label: {
                            if model.resendSeconds > 0 {
                                Text(String(format: String(localized: "security.resend.remainingFormat"), model.resendSeconds))
                            } else {
                                Text("security.resend")
                            }
                        }
                        .disabled(!model.canResend)
                    }

                    if model.tokenExpired {
                        Text("security.token.expired").foregroundStyle(Color.errorColor)
                    }

                    SubmitButton(title: actionTitle, form: model.form) {
                        Task { await model.submit() }
                    }

                    if model.step != .currentPassword {
                        Button("security.restart") { model.restart() }
                            .disabled(model.isLoading)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("security.changePassword")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            while !Task.isCancelled {
                model.refreshTime()
                do { try await Task.sleep(for: .seconds(1)) }
                catch { break }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshTime() }
        }
    }

    @ViewBuilder private var fields: some View {
        switch model.step {
        case .currentPassword:
            AppPasswordField(text: $model.currentPassword, placeholder: String(localized: "security.current"))
                .frame(height: 56)
                .fieldValidation(model.form[.currentPassword])
        case .code:
            Text("security.code.description")
                .font(.subheadline).foregroundStyle(Color.descriptionText)
            OTPRepresentable(code: $model.code, digitCount: 6)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .fieldValidation(model.form[.code])
        case .newPassword:
            AppPasswordField(text: $model.newPassword, placeholder: String(localized: "security.new"))
                .frame(height: 56)
                .fieldValidation(model.form[.password])
            AppPasswordField(text: $model.confirmation, placeholder: String(localized: "security.confirm"))
                .frame(height: 56)
                .fieldValidation(model.form[.confirmation])
            PasswordRequirementsView(password: model.newPassword)
        case .complete: EmptyView()
        }
    }

    private var stepTitle: LocalizedStringKey {
        switch model.step {
        case .currentPassword: "security.step.current"
        case .code: "security.step.code"
        case .newPassword: "security.step.new"
        case .complete: "security.success"
        }
    }

    private var actionTitle: LocalizedStringKey {
        switch model.step {
        case .currentPassword: "security.send"
        case .code: "security.verify"
        case .newPassword: "security.save"
        case .complete: "common.ok"
        }
    }
}
