import SwiftUI

struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.listings) { listing in
                    ListingCard(
                        listing: listing, isFavorite: true,
                        isUpdatingFavorite: viewModel.removingIDs.contains(listing.id)
                    ) {
                        Task { await viewModel.remove(listing) }
                    }
                }
                if case .error(let error) = viewModel.state {
                    ErrorStateView(
                        title: "favorites.error", message: error,
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
        .task(id: appState.language) { await viewModel.load(locale: appState.language.rawValue) }
        .refreshable { await viewModel.refresh(locale: appState.language.rawValue) }
        .alert("favorites.error", isPresented: Binding(
            get: {
                if case .error = viewModel.removalState { return true }
                return false
            },
            set: { if !$0 { viewModel.dismissRemovalError() } }
        )) {
            Button("favorites.ok", role: .cancel) { viewModel.dismissRemovalError() }
        } message: {
            if case .error(let message) = viewModel.removalState {
                Text(message)
            }
        }
    }
}
