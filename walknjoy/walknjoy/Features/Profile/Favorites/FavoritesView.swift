import SwiftUI

struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @State private var favoriteError: String?
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.listings) { listing in
                    SearchListingRow(
                        listing: listing,
                        isFavorite: appState.isFavorite(listing),
                        isUpdatingFavorite: appState.updatingFavoriteIDs
                            .contains(listing.id),
                        canFavorite: appState.canUseFavorites,
                        usesProfileRoute: true,
                        onFavorite: {
                            Task {
                                do {
                                    try await appState.setFavorite(
                                        false,
                                        for: listing
                                    )
                                    await viewModel.refresh(
                                        locale: appState.language.rawValue
                                    )
                                } catch {
                                    favoriteError = error.localizedDescription
                                }
                            }
                        }
                    )
                    .task {
                        if listing.id == viewModel.listings.last?.id {
                            await viewModel.loadNextPage()
                        }
                    }
                }
                if case .error(let error) = viewModel.state {
                    ErrorStateView(
                        title: "favorites.error",
                        message: error,
                        retryTitle: "favorites.retry"
                    ) {
                        Task { await viewModel.loadNextPage() }
                    }
                } else if viewModel.hasMore {
                    LoadingStateView()
                        .onAppear { Task { await viewModel.loadNextPage() } }
                        .id(viewModel.nextPage)
                } else if viewModel.listings.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "favorites.empty.title",
                        message: "favorites.empty.description"
                    )
                }
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle("profile.favorites")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: .listingsChanged)) { event in
            if let id = event.object as? String { viewModel.invalidateDeletedListing(id) }
            Task { await viewModel.refresh(locale: appState.language.rawValue) }
        }
        .task(id: appState.language) {
            await viewModel.refresh(locale: appState.language.rawValue)
        }
        .refreshable {
            await viewModel.refresh(locale: appState.language.rawValue)
        }
        .alert(
            "favorites.error",
            isPresented: Binding(
                get: { favoriteError != nil },
                set: { if $0 { favoriteError = nil } }
            )
        ) {
            Button("favorites.ok", role: .cancel) { favoriteError = nil }
        } message: {
            Text(favoriteError ?? "")
        }
    }
}
