//
//  Profile.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

struct ProfileModel: Decodable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let roleRawValue: String
    let status: UserStatus
    let emailVerifiedAt: String?
    let createdAt: String
    let updatedAt: String?
    let avatarFile: UploadedFile?
    let stats: ProfileStats

    private enum CodingKeys: String, CodingKey {
        case id, email, firstName, lastName, phone, status, emailVerifiedAt
        case createdAt, updatedAt, avatarFile, stats
        case roleRawValue = "role"
    }

    var role: RoleEnum? {
        RoleEnum(rawValue: roleRawValue.uppercased())
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

extension ProfileModel {
    func replacingAvatar(_ avatar: UploadedFile?) -> ProfileModel {
        ProfileModel(
            id: id, email: email, firstName: firstName, lastName: lastName,
            phone: phone, roleRawValue: roleRawValue, status: status, emailVerifiedAt: emailVerifiedAt,
            createdAt: createdAt, updatedAt: updatedAt, avatarFile: avatar, stats: stats
        )
    }
}
