import SwiftUI

struct MyReviewsView: View {
    @Environment(AppState.self) private var appState
    @State private var model = MyReviewsViewModel()
    @State private var editor: ReviewEditorContext?
    @State private var pendingDelete: MyReview?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if appState.currentUserRole == .customer {
                    ForEach(model.pagination.items) { review in
                        VStack(alignment: .leading, spacing: 8) {
                            ReviewCardView(
                                name: ReviewValidation.text(
                                    review.listing.title
                                )
                                    ?? String(
                                        localized: "reviews.listingUnavailable"
                                    ),
                                rating: review.rating,
                                title: review.title,
                                comment: review.comment,
                                date: review.createdAt,
                                hidden: review.status == .hidden,
                                onEdit: {
                                    editor = ReviewEditorContext(review)
                                },
                                onDelete: { pendingDelete = review },
                                isBusy: model.deletingID == review.id
                            )
                            if ReviewValidation.text(review.listing.slug) != nil
                            {
                                Button {
                                    Task {
                                        await model.open(
                                            review,
                                            locale: appState.language.rawValue
                                        )
                                    }
                                } label: {
                                    HStack {
                                        Text("reviews.openListing")
                                        if model.openingID == review.id {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "arrow.up.right")
                                        }
                                    }
                                }.font(.subheadline).frame(minHeight: 44)
                                    .disabled(model.openingID != nil)
                            }
                        }
                    }
                    ReviewLoadStateView(
                        state: model.pagination.state,
                        isEmpty: model.pagination.items.isEmpty
                    ) {
                        Task { await model.refresh(store: appState.reviews) }
                    }
                    if model.pagination.hasMore,
                        !model.pagination.items.isEmpty,
                        !model.pagination.isLoading
                    {
                        Button("reviews.loadMore") {
                            Task {
                                await model.loadMore(store: appState.reviews)
                            }
                        }.frame(minHeight: 44)
                    }
                } else {
                    ContentUnavailableView(
                        "reviews.customerOnly",
                        systemImage: "person.crop.circle"
                    )
                }
            }.padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("profile.reviews").navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar(.visible, for: .navigationBar)
        .task(
            id: "\(appState.reviews.revision)-\(appState.currentUserID ?? "")"
        ) {
            guard appState.currentUserRole == .customer else { return }
            await model.refresh(store: appState.reviews)
        }
        .refreshable {
            guard appState.currentUserRole == .customer else { return }
            await model.refresh(store: appState.reviews)
        }
        .navigationDestination(item: $model.selectedListing) {
            ListingDetailView(data: $0)
        }
        .sheet(item: $editor) { ReviewEditorView(context: $0) }
        .confirmationDialog(
            "reviews.deleteConfirm",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let review = pendingDelete {
                Button("reviews.delete", role: .destructive) {
                    Task {
                        await model.delete(
                            review,
                            store: appState.reviews,
                            locale: appState.language.rawValue
                        )
                    }
                }
            }
            Button("common.cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("reviews.deleteMessage")
        }
        .alert(
            "error.title",
            isPresented: Binding(
                get: { model.error != nil },
                set: { if !$0 { model.error = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
    }
}
