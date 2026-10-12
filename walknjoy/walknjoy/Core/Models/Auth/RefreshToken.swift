//
//  RefreshToken.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 22.09.26.
//

import Foundation

nonisolated struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}
nonisolated struct RefreshTokenResponse:Decodable {
    let refreshToken: String
    let accessToken: String
}
