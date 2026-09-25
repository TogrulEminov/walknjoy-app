struct ChangePasswordRequest: Encodable {
    let currentPassword: String
}

struct ChangePasswordChallenge: Decodable {
    let expiresInSeconds: Int
    let resendAvailableInSeconds: Int
}

struct ChangePasswordVerification: Encodable {
    let code: String
}

struct ChangePasswordAuthorization: Decodable {
    let changePasswordToken: String
}

struct ChangePasswordInput: Encodable {
    let changePasswordToken: String
    let newPassword: String
}
