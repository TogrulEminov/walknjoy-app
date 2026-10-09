import Foundation
import Observation

@MainActor @Observable
final class MyReviewsViewModel {
    let pagination = PaginationController<MyReview>()
    let service: any ReviewServiceProtocol
    var deletingID: String?
    var openingID: String?
    var error: String?
    var selectedListing: PublicListing?

    init(service: (any ReviewServiceProtocol)? = nil) {
        self.service = service ?? ReviewService()
    }

    func refresh(store: ReviewStore) async {
        let service = service
        let session = store.sessionID
        let revision = store.revision
        await pagination.refresh { page, limit in
            try await service.mine(page: page, limit: limit)
        }
        guard session == store.sessionID, revision == store.revision else {
            return
        }
        store.remember(pagination.items)
    }

    func loadMore(store: ReviewStore) async {
        let session = store.sessionID
        let revision = store.revision
        await pagination.loadNextPage()
        guard session == store.sessionID, revision == store.revision else {
            return
        }
        store.remember(pagination.items)
    }

    func delete(_ review: MyReview, store: ReviewStore, locale: String) async {
        guard deletingID == nil else { return }
        deletingID = review.id
        error = nil
        let session = store.sessionID
        defer { deletingID = nil }
        do {
            try await service.delete(id: review.id)
            guard session == store.sessionID else { return }
            store.changed(listingID: review.listingId, review: nil)
            if let slug = ReviewValidation.text(review.listing.slug) {
                await store.refreshRating(
                    listingID: review.listingId,
                    slug: slug,
                    locale: locale,
                    service: service
                )
            }
        } catch is CancellationError {} catch {
            self.error = ReviewErrorMessage.text(error)
        }
    }

    func open(_ review: MyReview, locale: String) async {
        guard openingID == nil,
            let slug = ReviewValidation.text(review.listing.slug)
        else { return }
        openingID = review.id
        error = nil
        defer { openingID = nil }
        do {
            selectedListing = try await service.listing(
                slug: slug,
                locale: locale
            )
        } catch is CancellationError {} catch {
            self.error = ReviewErrorMessage.text(error)
        }
    }
}
