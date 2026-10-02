import Foundation

struct AvatarResponse: Decodable {
    let avatarFile: UploadedFile?
    let altText: String?

    init(avatarFile: UploadedFile?, altText: String?) {
        self.avatarFile = avatarFile
        self.altText = altText
    }

    private enum CodingKeys: String, CodingKey {
        case success, data, avatarFile, altText
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        let payload: KeyedDecodingContainer<CodingKeys>
        if root.contains(.success) || root.contains(.data) {
            guard try root.decode(Bool.self, forKey: .success) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .success, in: root, debugDescription: "Avatar operation failed"
                )
            }
            payload = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        } else {
            payload = root
        }
        guard payload.contains(.avatarFile) else {
            throw DecodingError.keyNotFound(
                CodingKeys.avatarFile,
                .init(codingPath: payload.codingPath, debugDescription: "Missing avatarFile")
            )
        }
        avatarFile = try payload.decodeIfPresent(UploadedFile.self, forKey: .avatarFile)
        altText = try payload.decodeIfPresent(String.self, forKey: .altText)
    }
}
