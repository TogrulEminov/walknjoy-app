//
//  RegisterRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

nonisolated struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}
nonisolated struct RegisterResponse: Decodable {
    let user: AuthUser
}
