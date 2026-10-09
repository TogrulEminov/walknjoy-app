//
//  MainView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

enum MainTab: Hashable {
    case home
    case search
    case ai
    case profile
}

struct MainView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: MainTab = .home
    @State private var searchCriteria = ListingSearchCriteria(type: .stay)
    var body: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tag(MainTab.home)
            searchView
                .tag(MainTab.search)
            if appState.hasLoadedCurrentUserRole,
                appState.currentUserRole == .customer
            {
                aiView
                    .tag(MainTab.ai)
            }
            profileView
                .tag(MainTab.profile)
        }
        .task { await appState.loadFavoriteAccess() }
    }
}
extension MainView {
    private var aiView: some View {
        NavigationStack {
            AITravelAssistantView()
        }
        .tabItem {
            Label("ai.assistant.title", systemImage: "ellipsis.bubble")
        }
    }

    private var searchView: some View {
        NavigationStack {
            SearchResultsView(criteria: searchCriteria)
                .id(searchCriteria)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .tabItem {
            Label("search.main", systemImage: "magnifyingglass")
        }
    }

    private var profileView: some View {
        ProfileView()
            .tabItem {
                Label("profile.main", systemImage: "person")
            }
    }
}
extension MainView {
    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .listingDetails(let listing):
            ListingDetailView(data: listing)
        case .allCategories:
            EmptyView()
        }
    }
}
extension MainView {
    private var homeView: some View {
        HomeView(
            selectedTab: $selectedTab,
            searchCriteria: $searchCriteria
        )
            .tabItem {
                Label("home.main", systemImage: "house")
            }
    }
}
