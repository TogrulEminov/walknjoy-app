//
//  ProfileEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import Foundation

enum ProfileEndpoint {
    case getProfile
    case updateProfile(UpdateProfileInput)
    case updateAvatar(UpdateAvatarInput)
    case deleteAvatar
    case notificationPreferences
    case updateNotificationPreferences(Notification)
}
extension ProfileEndpoint: Endpoint {
    var baseURL: String {
        APIConfig.baseURL
    }
    var path: String {
        switch self {
        case .notificationPreferences, .updateNotificationPreferences:
            "/profile/notification-preferences"
        case .getProfile, .updateProfile: "/profile"
        case .updateAvatar, .deleteAvatar: "/profile/avatar"
        }
    }
    var headers: [String: String]? {
        nil
    }
    var queryItems: [URLQueryItem]? {
        nil
    }
    var method: HttpMethod {
        switch self {
        case .getProfile:
            .get
        case .notificationPreferences: .get
        case .updateProfile, .updateNotificationPreferences:
            .patch
        case .updateAvatar: .post
        case .deleteAvatar:
            .delete
        }
    }

    var httpBody: RequestBody {
        switch self {
        case .updateNotificationPreferences(let input): .json(input)
        case .getProfile, .deleteAvatar, .notificationPreferences: .none
        case .updateProfile(let input): .json(input)
        case .updateAvatar(let input): .json(input)
        }
    }
    var requiresAuth: Bool {
        true
    }
}
