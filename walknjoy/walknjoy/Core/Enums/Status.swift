//
//  UserStatus.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

enum UserStatus: String, Codable {
    case active = "ACTIVE"
    case suspended = "SUSPENDED"
    case disabled = "DISABLED"
}
enum ProviderStatus: String, Codable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case suspended = "SUSPENDED"
}
