//
//  ForgotPasswordRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

struct EmptyResponse: Decodable {}
struct ForgotPasswordRequest:Encodable {
    let email:String
}
struct ForgotPasswordResponse:Decodable {
    let expiresInSeconds:Int
    let resendAvailableInSeconds:Int
}
