//
//  ForgotPasswordRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

nonisolated struct EmptyResponse: Decodable {}
nonisolated struct ForgotPasswordRequest:Encodable {
    let email:String
}
nonisolated struct ForgotPasswordResponse:Decodable {
    let expiresInSeconds:Int
    let resendAvailableInSeconds:Int
}
