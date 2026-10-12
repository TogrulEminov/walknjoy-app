//
//  ResetPasswordModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

nonisolated struct ResetPasswordRequest: Encodable {
    let resetToken: String
    let newPassword: String
}
