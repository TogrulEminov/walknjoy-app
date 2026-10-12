nonisolated struct ChangePasswordRequest: Encodable {
    let currentPassword: String
}

nonisolated struct ChangePasswordChallenge: Decodable {
    let expiresInSeconds: Int
    let resendAvailableInSeconds: Int
}

nonisolated struct ChangePasswordVerification: Encodable {
    let code: String
}

nonisolated struct ChangePasswordAuthorization: Decodable {
    let changePasswordToken: String
}

nonisolated struct ChangePasswordInput: Encodable {
    let changePasswordToken: String
    let newPassword: String
}
