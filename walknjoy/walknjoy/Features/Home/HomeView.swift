//
//  HomeView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import SwiftUI

@MainActor
struct HomeView: View {
    @Binding var selectedTab: MainTab
    @Binding var searchCriteria: ListingSearchCriteria
    @Environment(AppState.self) private var appState
    @State private var favoriteError: String?
    @Environment(NotificationViewModel.self) private var notifications
    @State private var viewModel: HomeViewModel
    @State private var showNotifications = false

    @MainActor
    init(
        selectedTab: Binding<MainTab>,
        searchCriteria: Binding<ListingSearchCriteria>
    ) {
        _selectedTab = selectedTab
        _searchCriteria = searchCriteria
        _viewModel = State(initialValue: HomeViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    Color.appBg

                case .loading:
                    LoadingStateView()

                case .loaded(let content):
                    contentView(content)

                case .error(let message):
                    ErrorStateView(title: "error.title", message: message) {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
                    .toolbar(.visible, for: .navigationBar)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showNotifications) {
                NotificationListView()
                    .toolbar(.visible, for: .navigationBar)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg)
        .alert(
            "favorites.error",
            isPresented: Binding(
                get: { favoriteError != nil },
                set: { if !$0 { favoriteError = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { favoriteError = nil }
        } message: {
            Text(favoriteError ?? "")
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}
extension HomeView {
    private func contentView(_ content: HomeContent) -> some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 28) {
                    HomeHeroView(
                        topInset: geometry.safeAreaInsets.top,
                        unreadCount: notifications.unreadCount,
                        onNotificationTap: { showNotifications = true }
                    ) {
                        HomeSearchView(
                            criteria: $searchCriteria,
                            cities: content.cities,
                            onImage: true
                        ) {
                            searchCriteria.page = 1
                            selectedTab = .search
                        }
                    }
                    HomeListingTypesView { type in
                        handleSeeAll(type)
                    }
                    if !content.categories.isEmpty {
                        HomeCategoriesView(
                            categories: content.categories,
                            onSelect: handleCategoryTap
                        )
                    }
                    if appState.hasLoadedCurrentUserRole,
                        appState.currentUserRole == .customer
                    {
                        AITravelBannerView {
                            handleAITravelTap()
                        }
                    }
                    listingSection(
                        title: "home.stays.title",
                        type: .stay,
                        listings: content.stays
                    )

                    listingSection(
                        title: "home.tours.title",
                        type: .tour,
                        listings: content.tours
                    )

                    listingSection(
                        title: "home.activities.title",
                        type: .activity,
                        listings: content.activities
                    )

                    listingSection(
                        title: "home.experiences.title",
                        type: .experience,
                        listings: content.experiences
                    )
                    AdvantagesSection()
                    if appState.hasLoadedCurrentUserRole,
                        let role = appState.currentUserRole,
                        role != .provider
                    {
                        ProviderApplySection()
                    }
                }
                .padding(.bottom, 16)
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(Color.appBg)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}
extension HomeView {

    @ViewBuilder
    private func listingSection(
        title: LocalizedStringKey,
        type: ListingType,
        listings: [ListingResponse]
    ) -> some View {
        if !listings.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    title: title,
                    type: type
                )

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {
                    LazyHStack(spacing: 16) {
                        ForEach(listings) { listing in
                            ListingCard(
                                listing: listing,
                                isFavorite: appState.isFavorite(listing),
                                isUpdatingFavorite: appState.updatingFavoriteIDs
                                    .contains(listing.id),
                                canFavorite: appState.canUseFavorites
                            ) {
                                handleFavoriteTap(listing)
                            }
                        }
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

extension HomeView {

    private func sectionHeader(
        title: LocalizedStringKey,
        type: ListingType
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(
                    .system(
                        size: 22,
                        weight: .bold
                    )
                )
                .foregroundStyle(Color.title)

            Spacer()

            Button {
                handleSeeAll(type)
            } label: {
                HStack(spacing: 6) {
                    Text("common.seeAll")
                        .font(
                            .system(
                                size: 14,
                                weight: .medium
                            )
                        )

                    Image(systemName: "chevron.right")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(Color.icon)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
}
extension HomeView {

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .listingDetails(let listing):
            ListingDetailView(data: listing)
                .toolbar(.visible, for: .navigationBar)
        case .allCategories:
            if case .loaded(let content) = viewModel.state {
                HomeAllCategoriesView(
                    categories: content.categories,
                    onSelect: handleCategoryTap
                )
                    .toolbar(.visible, for: .navigationBar)
            }
        }
    }

    private func handleCategoryTap(_ category: CategoryModel) {
        var criteria = searchCriteria
        criteria.categoryId = category.id
        criteria.page = 1
        searchCriteria = criteria
        selectedTab = .search
    }

    private func handleAITravelTap() {
        selectedTab = .ai
    }

    private func handleSeeAll(
        _ type: ListingType
    ) {
        var criteria = searchCriteria
        criteria.type = type
        criteria.categoryId = nil
        criteria.amenityIds = []
        criteria.page = 1
        searchCriteria = criteria
        selectedTab = .search
    }

    private func handleFavoriteTap(
        _ listing: ListingResponse
    ) {
        Task {
            do {
                try await appState.setFavorite(
                    !appState.isFavorite(listing),
                    for: listing
                )
            } catch { favoriteError = error.localizedDescription }
        }
    }
}
