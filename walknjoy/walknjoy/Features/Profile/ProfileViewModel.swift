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
    private let providerService: ProviderServiceProtocol
    private(set) var state: LoadState<ProfileModel> = .idle
    private let authService: AuthServiceProtocol
    private(set) var isApprovedProvider = false
    init(
        profileService: ProfileServiceProtocol? = nil,
        authService: AuthServiceProtocol? = nil,
        providerService: ProviderServiceProtocol? = nil
    ) {
        self.profileService = profileService ?? ProfileService()
        self.authService = authService ?? AuthService()
        self.providerService = providerService ?? ProviderService()
    }

    func loadProfile(isRefreshing: Bool = false) async {
        let preserveContent: Bool
        if case .loaded = state { preserveContent = isRefreshing }
        else { preserveContent = false }
        if !preserveContent { state = .loading }
        do {
            let profile = try await profileService.getProfile()
            try MobileAccountAccess.validate(role: profile.roleRawValue)
            if profile.role == .provider {
                isApprovedProvider =
                    (try? await providerService.getProfile().status)
                    == .approved
            } else {
                isApprovedProvider = false
            }
            state = .loaded(profile)
        } catch {
            if !preserveContent { state = .error(error.localizedDescription) }
        }
    }

    func setProfile(_ profile: ProfileModel) {
        do {
            try MobileAccountAccess.validate(role: profile.roleRawValue)
            state = .loaded(profile)
            if profile.role != .provider { isApprovedProvider = false }
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
    var canViewBookings: Bool {
        switch profile?.role {
        case .customer, .admin: true
        case .provider: isApprovedProvider
        case nil: false
        }
    }

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
        ].filter { item in
            switch item.destination {
            case .bookings: canViewBookings
            case .favorites, .reviews: canViewFavorites
            default: true
            }
        }
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
                ),
            ]
        }

    }
}
