//
//  MainView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

struct MainView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        TabView {
            homeView
            searchView
            profileView
        }
        .task { await appState.loadFavoriteAccess() }
    }
}
extension MainView {
    private var searchView: some View {
        NavigationStack {
            SearchResultsView(criteria: ListingSearchCriteria())
                .navigationDestination(for: ListingDetailsRoute.self) { route in
                    ListingDetailView(data: route.listing)
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
    private var homeView: some View {
        HomeView()
            .tabItem {
                Label("home.main", systemImage: "house")
            }
    }
}
