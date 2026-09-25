//
//  VerifyForgotPasswordOTPRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

struct VerifyForgotPasswordOTPRequest: Encodable {
    let email: String
    let code: String
}
struct VerifyForgotPasswordOTPResponse: Decodable {
    let resetToken: String
}
