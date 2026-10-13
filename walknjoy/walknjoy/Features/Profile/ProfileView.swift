//
//  ProfileView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

@MainActor
struct ProfileView: View {

    @Environment(AppState.self) private var appState
    @State private var isAvatarSheetPresented = false
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    @State private var logoutError: String?
    @State private var path: [ProfileDestination] = []
    @State private var viewModel: ProfileViewModel

    init() {
        _viewModel = State(
            initialValue: ProfileViewModel()
        )
    }

    init(viewModel: ProfileViewModel) {
        _viewModel = State(
            initialValue: viewModel
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(
                    for: ProfileDestination.self
                ) { destination in
                    destinationView(
                        for: destination
                    )
                }
                .navigationTitle("profile.title")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    if case .idle = viewModel.state {
                        await viewModel.loadProfile()
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookingsChanged)) { _ in
            Task { await viewModel.loadProfile(isRefreshing: true) }
        }
        .alert(
            "profile.logoutConfirmTitle",
            isPresented: $showLogoutConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("profile.logout", role: .destructive) {
                Task { await confirmLogout() }
            }
        } message: {
            Text("profile.logoutConfirmMessage")
        }
        .alert(
            "error.title",
            isPresented: Binding(
                get: { logoutError != nil },
                set: { if !$0 { logoutError = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(logoutError ?? "")
        }
    }
}

// MARK: - Content

extension ProfileView {

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {

        case .idle:
            Color.clear

        case .loading:
            LoadingStateView()

        case .loaded(let profile):
            profileContent(profile)

        case .error(let message):
            ErrorStateView(
                title: "profile.error.title",
                message: message,
                retryTitle: "retry"
            ) {
                Task {
                    await viewModel.retry()
                }
            }
        }
    }
}

// MARK: - Profile Content

extension ProfileView {

    private func profileContent(
        _ profile: ProfileModel
    ) -> some View {
        ScrollView {
            VStack(spacing: 24) {

                ProfileHeaderView(
                    profile: profile
                ) {
                    handleNavigation(
                        .editProfile
                    )
                }

                ProfileStatsView(
                    stats: profile.stats
                )

                ProfileSectionView(
                    title: "profile.myAccount",
                    items: viewModel.accountItems
                ) { item in
                    handleNavigation(
                        item.destination
                    )
                }

                if let role = profile.role, !viewModel.roleItems.isEmpty {
                    ProfileSectionView(
                        title: roleSectionTitle(
                            for: role
                        ),
                        items: viewModel.roleItems
                    ) { item in
                        handleNavigation(
                            item.destination
                        )
                    }
                }

                ProfileSectionView(
                    title: "profile.settings",
                    items: viewModel.settingsItems
                ) { item in
                    handleNavigation(
                        item.destination
                    )
                }

                logoutButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            Color.appBackground
        )
    }
}

// MARK: - Role Section

extension ProfileView {

    private func roleSectionTitle(
        for role: RoleEnum
    ) -> LocalizedStringKey {
        switch role {

        case .customer:
            return ""

        case .provider:
            return "profile.business"

        case .admin:
            return ""
        }
    }
}

// MARK: - Logout

extension ProfileView {

    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack {
                Image(
                    systemName:
                        "rectangle.portrait.and.arrow.right"
                )

                Text("profile.logout")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.errorColor)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Color.errorColor.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoggingOut)
    }

    private func confirmLogout() async {
        guard !isLoggingOut else { return }
        isLoggingOut = true
        defer { isLoggingOut = false }
        do {
            try await viewModel.logout()
            appState.finishLogout()
        } catch {
            logoutError = error.localizedDescription
        }
    }
}

// MARK: - Navigation

extension ProfileView {

    private func handleNavigation(
        _ destination: ProfileDestination
    ) {
        guard destination != .favorites || viewModel.canViewFavorites else {
            return
        }
        guard destination != .bookings || viewModel.canViewBookings else {
            return
        }
        path.append(destination)
    }
}

// MARK: - Destinations

extension ProfileView {
    @ViewBuilder
    private func destinationView(
        for destination: ProfileDestination
    ) -> some View {
        switch destination {

        case .listingDetails(let listing):
            ListingDetailView(data: listing)

        case .editProfile:
            if let profile = viewModel.profile {
                EditProfileView(
                    viewModel: EditProfileViewModel(profile: profile)
                ) { updatedProfile in
                    viewModel.setProfile(updatedProfile)
                }
            } else {
                EmptyView()
            }

        case .bookings:
            if let profile = viewModel.profile, viewModel.canViewBookings {
                BookingListView(role: profile.role ?? .customer)
            } else {
                EmptyView()
            }

        case .bookingDetail(let id, let role):
            BookingDetailView(bookingID: id, role: role)

        case .favorites:
            if viewModel.canViewFavorites {
                FavoritesView()
            }

        case .reviews:
            MyReviewsView()

        case .preferences:
            PreferencesView()

        case .notifications:
            NotificationPreferencesView()

        case .security:
            SecurityView()

        case .businessProfile:
            ProviderBusinessProfileView()

        case .businessDashboard:
            ListingListView()
        }
    }
}
