//
//  LoginRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

nonisolated struct LoginRequest:Encodable {
    let email:String
    let password:String
}
nonisolated struct LoginResponse: Decodable {
    let user: AuthUser
    let accessToken: String
    let refreshToken: String
}
