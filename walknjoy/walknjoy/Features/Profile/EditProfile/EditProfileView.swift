import SwiftUI

@MainActor
struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EditProfileViewModel
    @State private var singleFiles: [UploadFileItem] = []

    let onProfileUpdated: (ProfileModel) -> Void

    init(
        viewModel: EditProfileViewModel,
        onProfileUpdated: @escaping (ProfileModel) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onProfileUpdated = onProfileUpdated
    }

    var body: some View {
        Form {
            Section {
                avatarSection
                if let item = singleFiles.first, case .failed(let message) = item.state {
                    VStack(alignment: .leading, spacing: 8) {
                        errorText(message)
                        Button("common.retry") {
                            Task { await UploadFileViewModel().retry(item, files: $singleFiles, onUploaded: attachAvatar) }
                        }
                        .disabled(isAvatarLoading)
                    }
                    .padding(12)
                }
                if viewModel.avatarErrorMessage != nil,
                   let item = singleFiles.first, case .uploaded = item.state {
                    Button("common.retry") {
                        if let file = item.uploadedFile {
                            Task { await attachAvatar(file) }
                        }
                    }
                        .disabled(isAvatarLoading)
                        .padding(12)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            profileFormSection

            Section {
                LabeledContent("input.email") {
                    Text(viewModel.profile.email)
                        .foregroundStyle(Color.descriptionText)
                        .textSelection(.enabled)
                }
            }
            .listRowBackground(Color.surfaceBackground)

            Section {
                saveSection
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .disabled(viewModel.isSaving)
        .background(Color.appBackground)
        .navigationTitle("profile.editProfile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Avatar

extension EditProfileView {

    private var avatarSection: some View {
        HStack(spacing: 14) {

            avatar

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(viewModel.profile.fullName)
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Color.titleText)
                    .lineLimit(1)

                Text(viewModel.profile.email)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.descriptionText)
                    .lineLimit(1)

                if let role = viewModel.profile.role {
                    ProfileRoleBadge(role: role)
                        .padding(.top, 3)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            if viewModel.profile.avatarFile != nil {
                deleteAvatarButton
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceBackground)
        .overlay {
            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                Color.borderColor,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .overlay(alignment: .bottom) {
            if let error = viewModel.avatarErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.errorColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.surfaceBackground)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(
                                Color.errorColor.opacity(0.35),
                                lineWidth: 1
                            )
                    }
                    .offset(y: 18)
            }
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {

            currentAvatar

            if isAvatarLoading {
                avatarLoadingOverlay
            }

            Group {
                UploadFileView(
                    mode: .single,
                    files: $singleFiles,
                    showsPreviews: false,
                    onUploaded: attachAvatar
                ) {
                    cameraButton
                }
                .disabled(isAvatarLoading)
                .opacity(isAvatarLoading ? 0 : 1)
            }
        }
        .frame(width: 80, height: 80)
    }

    private var cameraButton: some View {
        Image(systemName: "camera.fill")
            .font(
                .system(
                    size: 11,
                    weight: .semibold
                )
            )
            .foregroundStyle(Color.buttonText)
            .frame(width: 28, height: 28)
            .background(Color.buttonBackground)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(
                        Color.surfaceBackground,
                        lineWidth: 2
                    )
            }
    }

    private var avatarLoadingOverlay: some View {
        ZStack {
            Circle()
                .fill(
                    Color.black.opacity(0.72)
                )

            ProgressView()
                .tint(Color.brandYellow)
                .controlSize(.regular)
        }
        .frame(width: 80, height: 80)
        .transition(.opacity)
    }

    private var currentAvatar: some View {
        AvatarImageView(file: viewModel.profile.avatarFile, size: 80)
            .id(viewModel.profile.avatarFile?.id)
            .overlay {
                Circle().stroke(Color.borderColor, lineWidth: 1)
            }
    }

    private var deleteAvatarButton: some View {
        Button(role: .destructive) {
            Task {
                await deleteAvatar()
            }
        } label: {
            Image(systemName: "trash")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Color.errorColor)
                .frame(width: 36, height: 36)
                .background(
                    Color.errorColor.opacity(0.10)
                )
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(
                            Color.errorColor.opacity(0.15),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .disabled(isAvatarLoading)
        .opacity(
            isAvatarLoading
                ? 0.45
                : 1
        )
        .accessibilityLabel(
            Text("profile.avatar.delete")
        )
    }

    private var isAvatarLoading: Bool {
        if viewModel.isAvatarProcessing {
            return true
        }

        return singleFiles.contains { item in
            if case .uploading = item.state {
                return true
            }

            return false
        }
    }
}

// MARK: - Profile Form

extension EditProfileView {

    private var profileFormSection: some View {
        Section {
            formField(
                title: "profile.firstName"
            ) {
                InputFieldRepresentable(
                    text: $viewModel.firstName,
                    placeholder: String(
                        localized:
                            "profile.firstName.placeholder"
                    ),
                    icon: "person",
                    textContentType: .givenName,
                    autocapitalizationType: .words
                )
                .frame(height: 56)
                .fieldValidation(viewModel.form[.firstName])
            }

            formField(
                title: "profile.lastName"
            ) {
                InputFieldRepresentable(
                    text: $viewModel.lastName,
                    placeholder: String(
                        localized:
                            "profile.lastName.placeholder"
                    ),
                    icon: "person",
                    textContentType: .familyName,
                    autocapitalizationType: .words
                )
                .frame(height: 56)
                .fieldValidation(viewModel.form[.lastName])
            }

            phoneField
        } header: {
            Text("profile.personalInformation")
        } footer: {
            Text("profile.personalInformation.description")
        }
        .listRowBackground(Color.surfaceBackground)
    }

    private var phoneField: some View {
        formField(
            title: "profile.phone"
        ) {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                countryPicker

                PhoneFieldRepresentable(
                    country: viewModel.phoneCountry,
                    phone: $viewModel.phone,
                    isComplete:
                        $viewModel.isPhoneComplete
                )
                .frame(height: 56)
                .fieldValidation(viewModel.form[.phone])


            }
        }
    }

    private var countryPicker: some View {
        Menu {
            ForEach(
                PhoneCountry.allCases
            ) { country in

                Button {
                    guard viewModel.phoneCountry != country else { return }

                    viewModel.phone = ""
                    viewModel.isPhoneComplete = false
                    viewModel.phoneCountry = country
                } label: {
                    Text(country.title)
                }
            }

        } label: {
            HStack(spacing: 10) {

                Image(
                    systemName: "globe"
                )
                .font(.system(size: 16))
                .foregroundStyle(
                    Color.iconColor
                )
                .frame(width: 22)

                Text(
                    viewModel.phoneCountry.title
                )
                .font(.system(size: 15))
                .foregroundStyle(
                    Color.titleText
                )

                Spacer()

                Text(
                    viewModel.phoneCountry.dialCode
                )
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.descriptionText
                )

                Image(
                    systemName:
                        "chevron.down"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.iconColor
                )
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                Color.surfaceBackground
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14
                )
                .stroke(
                    Color.borderColor,
                    lineWidth: 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
    }

    private func formField<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text(title)
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.titleText
                )

            content()
        }
    }
}

// MARK: - Save

extension EditProfileView {

    private var saveSection: some View {
        VStack(spacing: 10) {

            if let error =
                viewModel.saveErrorMessage
            {

                errorText(error)
            }

            saveButton
        }
    }

    private var saveButton: some View {
        SubmitButton(
            title: "profile.saveChanges",
            icon: "checkmark",
            form: viewModel.form,
            isBlocked: isAvatarLoading
        ) {
            Task { await saveProfile() }
        }
    }

}

// MARK: - Error UI

extension EditProfileView {

    private func errorText(
        _ message: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 8
        ) {
            Image(
                systemName:
                    "exclamationmark.circle.fill"
            )

            Text(message)
                .font(.caption)

            Spacer()
        }
        .foregroundStyle(
            Color.errorColor
        )
        .padding(12)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color.errorColor.opacity(0.08)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 12
            )
            .stroke(
                Color.errorColor.opacity(0.20),
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}

// MARK: - Actions

extension EditProfileView {

    private func attachAvatar(_ file: UploadedFile) async {
        let previewData = singleFiles.first(where: { $0.uploadedFile?.id == file.id })?.previewData
        let previousID = viewModel.profile.avatarFile?.id
        let updated = await viewModel.updateAvatar(fileId: file.id)
        guard updated else { return }
        if let previewData, let image = UIImage(data: previewData) {
            AvatarImageCache.shared.store(image, for: file.id)
        }
        if let previousID, previousID != file.id {
            AvatarImageCache.shared.remove(previousID)
        }
        onProfileUpdated(viewModel.profile)
        singleFiles = []
    }

    private func deleteAvatar() async {
        let previousID = viewModel.profile.avatarFile?.id
        let deleted =
            await viewModel.deleteAvatar()

        guard deleted else {
            return
        }

        if let previousID { AvatarImageCache.shared.remove(previousID) }
        singleFiles = []

        onProfileUpdated(
            viewModel.profile
        )
    }

    private func saveProfile() async {
        guard !isAvatarLoading else { return }
        let saved =
            await viewModel.save()

        
        guard saved else {
            return
        }

        onProfileUpdated(
            viewModel.profile
        )

        dismiss()
    }
}
