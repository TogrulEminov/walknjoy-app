import SwiftUI

@MainActor
struct ProviderApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flow: ProviderFlowViewModel
    @State private var form: ProviderProfileFormViewModel
    @State private var didSubmit = false
    private let isEditing: Bool

    init() {
        _flow = State(initialValue: ProviderFlowViewModel())
        _form = State(initialValue: ProviderProfileFormViewModel())
        isEditing = false
    }

    init(profile: ProviderProfile, flow: ProviderFlowViewModel) {
        _flow = State(initialValue: flow)
        _form = State(
            initialValue: ProviderProfileFormViewModel(profile: profile)
        )
        isEditing = true
    }

    var body: some View {
        @Bindable var form = form

        ScrollView {
            VStack(spacing: 18) {
                introCard

                formCard(title: "provider.apply.business", icon: "building.2") {
                    BusinessInputField(
                        "provider.apply.businessName",
                        text: $form.businessName,
                        icon: "building.2"
                    )
                    BusinessInputField(
                        "provider.apply.legalName",
                        text: $form.legalName,
                        icon: "doc.text"
                    )
                    BusinessInputField(
                        "provider.apply.taxId",
                        text: $form.taxId,
                        icon: "number"
                    )
                    BusinessInputField(
                        "provider.apply.logoUrl",
                        text: $form.logoUrl,
                        icon: "photo",
                        keyboard: .URL,
                        capitalization: .none
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            "provider.apply.descriptionField",
                            systemImage: "text.alignleft"
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.titleText)
                        TextEditor(text: $form.description)
                            .frame(minHeight: 110)
                            .foregroundStyle(Color.titleText)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(
                                Color.appBackground,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            }
                            .accessibilityLabel(
                                "provider.apply.descriptionField"
                            )
                    }
                }

                formCard(title: "provider.apply.contact", icon: "phone") {
                    BusinessInputField(
                        "provider.apply.phone",
                        text: $form.phone,
                        icon: "phone",
                        keyboard: .phonePad,
                        capitalization: .none
                    )
                    BusinessInputField(
                        "provider.apply.email",
                        text: $form.email,
                        icon: "envelope",
                        keyboard: .emailAddress,
                        capitalization: .none
                    )
                    BusinessInputField(
                        "provider.apply.website",
                        text: $form.website,
                        icon: "link",
                        keyboard: .URL,
                        capitalization: .none
                    )
                }

                if let validationMessage = form.validationMessage {
                    Label(
                        validationMessage,
                        systemImage: "exclamationmark.circle"
                    )
                    .font(.footnote)
                    .foregroundStyle(Color.errorColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage = form.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            "provider.apply.error",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.errorColor)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.titleText)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        Color.errorColor.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 96)
        }
        .background(Color.appBackground)
        .navigationTitle(
            isEditing ? "provider.profile.title" : "provider.apply.title"
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(
                placement: isEditing ? .topBarTrailing : .cancellationAction
            ) {
                Button("common.close") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomAction
        }
        .alert(
            isEditing
                ? "provider.profile.saved.title"
                : "provider.apply.success.title",
            isPresented: $didSubmit
        ) {
            Button("common.close") { dismiss() }
        } message: {
            Text(
                isEditing
                    ? "provider.profile.saved.message"
                    : "provider.apply.success.message"
            )
        }
        .tint(Color.buttonBackground)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.brandInk)
                .frame(width: 48, height: 48)
                .background(
                    Color.brandYellow,
                    in: RoundedRectangle(cornerRadius: 15)
                )

            Text(
                isEditing
                    ? "provider.profile.heading" : "provider.apply.heading"
            )
            .font(.title3.bold())
            .foregroundStyle(Color.titleText)

            Text(
                isEditing
                    ? "provider.profile.description"
                    : "provider.apply.description"
            )
            .font(.subheadline)
            .foregroundStyle(Color.descriptionText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            SubmitButton(
                title: isEditing
                    ? "provider.profile.save" : "provider.apply.submit",
                icon: isEditing ? "checkmark" : "arrow.right",
                isLoading: form.isSubmitting,
                isDisabled: !form.canSubmit
            ) {
                Task {
                    if await form.submit(using: flow) {
                        didSubmit = true
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                Color.buttonBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.appBackground)
    }

    private func formCard<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Color.titleText)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }
}
