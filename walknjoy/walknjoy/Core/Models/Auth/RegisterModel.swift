//
//  RegisterRequest.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}
struct RegisterResponse: Decodable {
    let user: AuthUser
}
