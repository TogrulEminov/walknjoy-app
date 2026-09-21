//
//  AuthUser.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

struct AuthUser: Decodable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String

    let phone: String?
    let avatarUrl: String?

    let role: String
    let status: String

    let emailVerifiedAt: Date?

    let createdAt: Date
    let updatedAt: Date
}
