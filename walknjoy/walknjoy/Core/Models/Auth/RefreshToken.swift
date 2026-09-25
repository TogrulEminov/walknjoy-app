//
//  RefreshToken.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 22.09.26.
//

import Foundation

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}
struct RefreshTokenResponse:Decodable {
    let refreshToken: String
    let accessToken: String
}
