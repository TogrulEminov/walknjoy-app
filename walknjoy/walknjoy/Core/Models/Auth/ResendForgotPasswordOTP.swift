//
//  ResendForgotPasswordOTP.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 22.09.26.
//

struct ResendForgotPasswordOTPRequest: Encodable {
    let email: String
}

struct ResendForgotPasswordOTPResponse: Decodable {
    let expiresInSeconds: Int
    let resendAvailableInSeconds: Int
}
