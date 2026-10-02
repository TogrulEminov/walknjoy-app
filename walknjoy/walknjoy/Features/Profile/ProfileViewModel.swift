//
//  ProfileViewModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import Foundation
import Observation

@MainActor
@Observable

final class ProfileViewModel {
    private let profileService: ProfileServiceProtocol
    private(set) var state: LoadState<ProfileModel> = .idle
    private let authService: AuthServiceProtocol
    init(
        profileService: ProfileServiceProtocol? = nil,
        authService: AuthServiceProtocol? = nil
    ) {
        self.profileService = profileService ?? ProfileService()
        self.authService = authService ?? AuthService()
    }

    func loadProfile() async {
        state = .loading
        do {
            let profile = try await profileService.getProfile()
            try MobileAccountAccess.validate(role: profile.roleRawValue)
            state = .loaded(profile)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func setProfile(_ profile: ProfileModel) {
        do {
            try MobileAccountAccess.validate(role: profile.roleRawValue)
            state = .loaded(profile)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    func logout() async throws {
        try await authService.logout()
    }
    func retry() async {
        await loadProfile()
    }
}
extension ProfileViewModel {
    var profile: ProfileModel? {
        guard case .loaded(let profile) = state else {
            return nil
        }
        return profile
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }

        return false
    }
}
extension ProfileViewModel {

    // MARK: - Account

    var canViewFavorites: Bool { profile?.role == .customer }

    var accountItems: [ProfileMenuItem] {
        [
            ProfileMenuItem(
                title: "profile.editProfile",
                icon: "person",
                destination: .editProfile
            ),

            ProfileMenuItem(
                title: "profile.bookings",
                icon: "calendar",
                destination: .bookings
            ),

            ProfileMenuItem(
                title: "profile.favorites",
                icon: "heart",
                destination: .favorites
            ),

            ProfileMenuItem(
                title: "profile.reviews",
                icon: "star",
                destination: .reviews
            ),
        ].filter { $0.destination != .favorites || canViewFavorites }
    }

    // MARK: - Settings

    var settingsItems: [ProfileMenuItem] {
        [
            ProfileMenuItem(
                title: "settings.preferences",
                icon: "slider.horizontal.3",
                destination: .preferences
            ),

            ProfileMenuItem(
                title: "profile.notifications",
                icon: "bell",
                destination: .notifications
            ),

            ProfileMenuItem(
                title: "security.changePassword",
                icon: "lock",
                destination: .security
            ),
        ]
    }
}
extension ProfileViewModel {

    // MARK: - Role

    var roleItems: [ProfileMenuItem] {
        guard let profile else {
            return []
        }

        switch profile.role {
        case nil: return []
        case .admin?, .customer?:
            return []

        case .provider?:
            return [
                ProfileMenuItem(
                    title: "profile.businessProfile",
                    icon: "building.2",
                    destination: .businessProfile
                ),
                ProfileMenuItem(
                    title: "profile.businessDashboard",
                    icon: "briefcase",
                    destination: .businessDashboard
                )
            ]
        }

    }
}
