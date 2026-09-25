import Foundation

protocol ProfileServiceProtocol {
    func getProfile() async throws -> ProfileModel
    func updateProfile(_ input: UpdateProfileInput) async throws -> ProfileModel
    func updateAvatar(fileId: String, altText: String?) async throws -> AvatarResponse
    func deleteAvatar() async throws -> AvatarResponse
}

final class ProfileService: ProfileServiceProtocol {
    var updates = 0
    var reads = 0
    let image = UploadedFile(id: "new", url: "new.jpg", originalName: "photo.jpg", mimeType: "image/jpeg", sizeBytes: 10)
    var initial: ProfileModel {
        ProfileModel(id: "1", email: "test@example.com", firstName: "Ada", lastName: "Lovelace",
                     phone: nil, role: .customer, status: .active, emailVerifiedAt: nil,
                     createdAt: "", updatedAt: nil, avatarFile: image,
                     stats: ProfileStats(bookings: 0, favorites: 0, reviews: 0))
    }
    func getProfile() async throws -> ProfileModel {
        reads += 1
        return initial.replacingAvatar(nil) // Simulate a stale read after uploading.
    }
    func updateProfile(_ input: UpdateProfileInput) async throws -> ProfileModel { initial }
    func updateAvatar(fileId: String, altText: String?) async throws -> AvatarResponse {
        updates += 1
        return AvatarResponse(avatarFile: image, altText: nil)
    }
    func deleteAvatar() async throws -> AvatarResponse { AvatarResponse(avatarFile: nil, altText: nil) }
}

@main struct AvatarChecks {
    @MainActor static func main() async {
        let service = ProfileService()
        let model = EditProfileViewModel(profile: service.initial, profileService: service)
        model.firstName = "Unsaved edit"
        let deleted = await model.deleteAvatar()
        precondition(deleted && model.profile.avatarFile == nil)
        let updated = await model.updateAvatar(fileId: "new")
        precondition(updated && model.profile.avatarFile?.id == "new")
        precondition(service.updates == 1 && service.reads == 0)
        precondition(model.firstName == "Unsaved edit")
        precondition(!model.isAvatarProcessing)
        print("PASS: delete then first upload uses mutation response, ignores stale reads, preserves unsaved fields")
    }
}
