//
//  ProfileService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import Foundation

protocol ProfileServiceProtocol {
    func getProfile() async throws -> ProfileModel
    func getNotificationPreferences() async throws -> Notification
    func updateProfile(_ input: UpdateProfileInput) async throws -> ProfileModel
    func updateAvatar(fileId: String, altText: String?) async throws
        -> AvatarResponse
    func updateNotification(_ input: Notification) async throws
        -> Notification
    func deleteAvatar() async throws -> AvatarResponse
}
final class ProfileService: ProfileServiceProtocol {
    private let networkService: NetworkingService

    init(
        networkService: NetworkingService? = nil,

    ) {
        self.networkService = networkService ?? DefaultNetworkService()
    }
    func getProfile() async throws -> ProfileModel {
        let response = try await networkService.request(
            enpoint: ProfileEndpoint.getProfile,
            responseType: ApiResponse<ProfileModel>.self
        )
        guard let data = response.data else {
            throw NetworkError.invalidResponse
        }

        return data
    }

    func updateProfile(_ input: UpdateProfileInput) async throws -> ProfileModel
    {
        let response = try await networkService.request(
            enpoint: ProfileEndpoint.updateProfile(input),
            responseType: ApiResponse<ProfileModel>.self
        )

        guard let profile = response.data else {
            throw NetworkError.invalidResponse
        }

        return profile
    }

    func updateAvatar(fileId: String, altText: String?) async throws
        -> AvatarResponse
    {
        let input = UpdateAvatarInput(fileId: fileId, altText: altText)

        let response = try await networkService.request(
            enpoint: ProfileEndpoint.updateAvatar(input),
            responseType: AvatarResponse.self
        )
        guard response.avatarFile?.id == fileId else {
            throw NetworkError.invalidResponse
        }
        return response

    }
    func deleteAvatar() async throws -> AvatarResponse {
        try await networkService.request(
            enpoint: ProfileEndpoint.deleteAvatar,
            responseType: AvatarResponse.self
        )
    }

    func updateNotification(_ input: Notification) async throws -> Notification
    {
        let response = try await networkService.request(
            enpoint: ProfileEndpoint.updateNotificationPreferences(input),
            responseType: ApiResponse<Notification>.self
        )
        guard response.success, let notification = response.data else {
            throw NetworkError.invalidResponse
        }

        return notification
    }
    func getNotificationPreferences() async throws -> Notification {
        let response = try await networkService.request(
            enpoint: ProfileEndpoint.notificationPreferences,
            responseType: ApiResponse<Notification>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }

        return data
    }
}
