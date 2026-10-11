import Foundation
import Observation
import SwiftUI
@MainActor
@Observable
final class EditProfileViewModel {

    private let profileService: ProfileServiceProtocol
    private let avatarCache: AvatarImageCaching

    private(set) var profile: ProfileModel

    var firstName: String
    var lastName: String
 
    var phone: String

    var phoneCountry: PhoneCountry
    var isPhoneComplete: Bool

    private(set) var isSaving = false
    private(set) var isAvatarProcessing = false

    private(set) var saveErrorMessage: String?
    private(set) var avatarErrorMessage: String?

    init(
        profile: ProfileModel,
        profileService: ProfileServiceProtocol? = nil,
        avatarCache: AvatarImageCaching? = nil
    ) {
        let country = PhoneCountry.detect(
            from: profile.phone
        )

        let localPhone = country.localNumber(
            from: profile.phone
        )

        self.avatarCache = avatarCache ?? AvatarImageService.shared
        self.profile = profile
        self.profileService = profileService ?? ProfileService()

        self.firstName = profile.firstName
        self.lastName = profile.lastName

        self.phoneCountry = country
        self.phone = localPhone

        self.isPhoneComplete =
            localPhone.count == country.digitCount

    }
}

// MARK: - Validation

extension EditProfileViewModel {
 
    var fullPhoneNumber: String {
        phoneCountry.fullNumber(
            from: phone
        )
    }

    enum Field { case firstName, lastName, phone }

    var form: FormState<Field> {
        FormState(fields: [
            .firstName: ValidatedField(
                value: firstName,
                rules: [.required("register.validation.firstName")],
                originalValue: profile.firstName,
                normalize: ValidatedField.trimmed
            ),
            .lastName: ValidatedField(
                value: lastName,
                rules: [.required("register.validation.lastName")],
                originalValue: profile.lastName,
                normalize: ValidatedField.trimmed
            ),
            .phone: ValidatedField(
                value: phone,
                rules: [.digits(phoneCountry.digitCount, optional: true, message: "profile.phone.invalid")],
                originalValue: normalizedOriginalPhone,
                normalize: { value in
                    value.hasPrefix("+") ? value : self.phoneCountry.fullNumber(from: value)
                }
            )
        ], isSubmitting: isSaving, isBlocked: isAvatarProcessing, requiresChanges: true)
    }

    private var normalizedOriginalPhone: String {
        let originalCountry = PhoneCountry.detect(from: profile.phone)
        return originalCountry.fullNumber(from: originalCountry.localNumber(from: profile.phone))
    }


}

// MARK: - Avatar

extension EditProfileViewModel {

    @discardableResult
    func updateAvatar(
        fileId: String,
        previewData: Data? = nil
    ) async -> Bool {

        guard !isAvatarProcessing && !isSaving else {
            return false
        }

        isAvatarProcessing = true
        avatarErrorMessage = nil

        defer {
            isAvatarProcessing = false
        }

        do {
            let previousID = profile.avatarFile?.id
            let response = try await profileService.updateAvatar(
                fileId: fileId,
                altText: nil
            )

            profile = profile.replacingAvatar(response.avatarFile)
            if let previewData { avatarCache.storePreview(previewData, for: fileId) }
            if let previousID, previousID != fileId { avatarCache.remove(previousID) }

            return true

        } catch {
            avatarErrorMessage =
                error.localizedDescription

            return false
        }
    }

    @discardableResult
    func deleteAvatar() async -> Bool {

        guard !isAvatarProcessing && !isSaving else {
            return false
        }

        isAvatarProcessing = true
        avatarErrorMessage = nil

        defer {
            isAvatarProcessing = false
        }

        do {
            let previousID = profile.avatarFile?.id
            let response = try await profileService.deleteAvatar()
            profile = profile.replacingAvatar(response.avatarFile)
            if let previousID { avatarCache.remove(previousID) }

            return true

        } catch {
            avatarErrorMessage =
                error.localizedDescription

            return false
        }
    }

    func clearAvatarError() {
        avatarErrorMessage = nil
    }
}

// MARK: - Profile Update

extension EditProfileViewModel {

    @discardableResult
    func save() async -> Bool {

        guard form.canSubmit else {
            return false
        }

        isSaving = true
        saveErrorMessage = nil

        defer {
            isSaving = false
        }

        let normalizedFirstName =
            firstName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let normalizedLastName =
            lastName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let currentPhone =
            normalizedOriginalPhone

        let newPhone =
            fullPhoneNumber

        let input = UpdateProfileInput(
            firstName:
                normalizedFirstName != profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                    ? normalizedFirstName
                    : nil,

            lastName:
                normalizedLastName != profile.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                    ? normalizedLastName
                    : nil,

            phone:
                newPhone != currentPhone
                    ? newPhone
                    : nil
        )
 

        do {
            let updatedProfile =
                try await profileService.updateProfile(
                    input
                )

            profile = updatedProfile

            syncForm()

            return true

        } catch {
            
            saveErrorMessage =
                error.localizedDescription

            return false
        }
    }
}

// MARK: - Sync Form

private extension EditProfileViewModel {

    func syncForm() {

        firstName =
            profile.firstName

        lastName =
            profile.lastName

        let country =
            PhoneCountry.detect(
                from: profile.phone
            )

        let localPhone =
            country.localNumber(
                from: profile.phone
            )

        phoneCountry =
            country

        phone =
            localPhone

        isPhoneComplete =
            localPhone.count ==
            country.digitCount
    }
}
