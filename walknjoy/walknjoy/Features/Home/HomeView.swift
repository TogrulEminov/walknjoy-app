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
    @Environment(NotificationViewModel.self) private var notifications
    @State private var favoriteError: String?
    @State private var viewModel: HomeViewModel
    @State private var showNotifications = false
    @State private var isScrolled = false
    @State private var isRefreshing = false

    @MainActor
    init(
        selectedTab: Binding<MainTab>,
        searchCriteria: Binding<ListingSearchCriteria>,
        viewModel: HomeViewModel? = nil
    ) {
        _selectedTab = selectedTab
        _searchCriteria = searchCriteria
        _viewModel = State(
            initialValue: viewModel ?? HomeViewModel.makeDefault()
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    Color.appBg

                case .loading:
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color.iconColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded(let content):
                    contentView(content)

                case .error(let message):
                    ErrorStateView(title: "error.title", message: message) {
                        Task { await viewModel.refresh() }
                    }
                }
            }
            .background(Color.appBg)
            .overlay(alignment: .top) { topBar }
            .overlay(alignment: .top) {
                if isRefreshing {
                    ProgressView()
                        .tint(Color.brandYellow)
                        .padding(.top, Self.topBarHeight + 12)
                        .allowsHitTesting(false)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
                    .toolbar(.visible, for: .navigationBar)
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .listingsChanged)) { _ in
            Task { await viewModel.refresh() }
        }
        .task(id: appState.language) {
            await viewModel.load(locale: appState.language.rawValue)
        }
    }
}

// MARK: - Top bar (logo solda, notification sağda)

extension HomeView {
    private var topBar: some View {
        HStack {
            Image(isScrolled ? "logo-colorfull" : "logo-white")
                .resizable()
                .scaledToFit()
                .frame(height: 30)
                .accessibilityHidden(true)

            Spacer()

            Button {
                showNotifications = true
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isScrolled ? Color.titleText : Color.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle().stroke(
                            isScrolled
                                ? Color.borderColor : Color.white.opacity(0.25),
                            lineWidth: 1
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        if notifications.unreadCount > 0 {
                            Text(badgeText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.errorC, in: Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("notifications.title")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(height: Self.topBarHeight)
        .animation(.easeInOut(duration: 0.2), value: isScrolled)
    }

    private static let topBarHeight: CGFloat = 56

    private var badgeText: String {
        notifications.unreadCount > 99 ? "99+" : "\(notifications.unreadCount)"
    }
}

// MARK: - Content

extension HomeView {
    private func contentView(_ content: HomeContent) -> some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 28) {
                    HomeHeroView(
                        topInset: geometry.safeAreaInsets.top
                            + Self.topBarHeight
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
            .onScrollGeometryChange(for: Bool.self) { scroll in
                scroll.contentOffset.y + scroll.contentInsets.top > 8
            } action: { _, newValue in
                isScrolled = newValue
            }
            .background(Color.appBg)
            .refreshable {
                guard !isRefreshing else { return }
                isRefreshing = true
                defer { isRefreshing = false }
                await viewModel.refresh()
            }
        }
    }
}

// MARK: - Sections

extension HomeView {
    @ViewBuilder
    private func listingSection(
        title: LocalizedStringKey,
        type: ListingType,
        listings: [ListingResponse]
    ) -> some View {
        if !listings.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(title: title, type: type)

                ScrollView(.horizontal, showsIndicators: false) {
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
                            .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func sectionHeader(
        title: LocalizedStringKey,
        type: ListingType
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.title)

            Spacer()

            Button {
                handleSeeAll(type)
            } label: {
                HStack(spacing: 6) {
                    Text("common.seeAll")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.icon)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Navigation & actions

extension HomeView {
    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .listingDetails(let listing):
            ListingDetailView(data: listing)
        case .allCategories:
            if case .loaded(let content) = viewModel.state {
                HomeAllCategoriesView(
                    categories: content.categories,
                    onSelect: handleCategoryTap
                )
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

    private func handleSeeAll(_ type: ListingType) {
        var criteria = searchCriteria
        criteria.type = type
        criteria.categoryId = nil
        criteria.amenityIds = []
        criteria.page = 1
        searchCriteria = criteria
        selectedTab = .search
    }

    private func handleFavoriteTap(_ listing: ListingResponse) {
        Task {
            do {
                try await appState.setFavorite(
                    !appState.isFavorite(listing),
                    for: listing
                )
            } catch {
                favoriteError = error.localizedDescription
            }
        }
    }
}
