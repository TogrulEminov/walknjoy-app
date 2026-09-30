//
//  HomeView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import SwiftUI

@MainActor
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var favoriteError: String?
    @Environment(NotificationViewModel.self) private var notifications
    @State private var viewModel: HomeViewModel
    @State private var searchCriteria = ListingSearchCriteria(type: .stay)
    @State private var showNotifications = false
    @State private var submittedCriteria: ListingSearchCriteria?

    init() {
        _viewModel = State(initialValue: HomeViewModel())
    }

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
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
            .navigationDestination(for: ListingDetailsRoute.self) { route in
                ListingDetailView(data: route.listing)
                    .toolbar(.visible, for: .navigationBar)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showNotifications) {
                NotificationListView()
                    .toolbar(.visible, for: .navigationBar)
            }
            .navigationDestination(item: $submittedCriteria) { criteria in
                SearchResultsView(criteria: criteria)
                    .toolbar(.visible, for: .navigationBar)
            }
            .navigationDestination(for: HomeNavigationRoute.self) { route in
                homeDestination(for: route)
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
                            submittedCriteria = searchCriteria
                        }
                    }
                    HomeListingTypesView { type in

                    }
                    if !content.categories.isEmpty {
                        HomeCategoriesView(
                            categories: content.categories
                        )
                    }
                    AITravelBannerView {
                        handleAITravelTap()
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
                            .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 20)
                }
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
    private func homeDestination(for route: HomeNavigationRoute) -> some View {
        switch route {
        case .allCategories:
            if case .loaded(let content) = viewModel.state {
                HomeAllCategoriesView(categories: content.categories)
                    .toolbar(.visible, for: .navigationBar)
            }
        case .category(let id):
            SearchResultsView(criteria: searchCriteria(forCategoryID: id))
                .toolbar(.visible, for: .navigationBar)
        }
    }

    private func searchCriteria(forCategoryID id: String) -> ListingSearchCriteria {
        var criteria = ListingSearchCriteria()
        criteria.categoryId = id
        return criteria
    }

    private func handleAITravelTap() {
        print("Open AI travel planner")
    }

    private func handleSeeAll(
        _ type: ListingType
    ) {
        switch type {
        case .stay:
            print("Open stays")

        case .tour:
            print("Open tours")

        case .activity:
            print("Open activities")

        case .experience:
            print("Open experiences")
        }
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
