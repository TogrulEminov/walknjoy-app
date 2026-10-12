import Foundation
import Observation

@MainActor @Observable
final class ReviewEditorViewModel {
    let context: ReviewEditorContext
    let service: any ReviewServiceProtocol
    var rating: Int
    var title: String
    var comment: String
    private(set) var isSubmitting = false
    var error: String?
    var fieldErrors: [String: String] = [:]
    private(set) var duplicate = false

    init(
        context: ReviewEditorContext,
        service: (any ReviewServiceProtocol)? = nil
    ) {
        self.context = context
        self.service = service ?? ReviewService()
        rating = context.rating
        title = context.title ?? ""
        comment = context.comment ?? ""
    }

    var patch: UpdateReviewRequest {
        UpdateReviewRequest(
            rating: rating == context.rating ? nil : rating,
            title: .comparing(title, to: context.title),
            comment: .comparing(comment, to: context.comment)
        )
    }

    var canSubmit: Bool {
        !isSubmitting && (1...5).contains(rating) && title.count <= 120
            && comment.count <= 2000
            && (context.reviewID != nil
                ? patch.hasChanges
                : ReviewValidation.text(context.bookingID) != nil)
    }

    func submit(store: ReviewStore, locale: String) async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        error = nil
        fieldErrors = [:]
        duplicate = false
        let session = store.sessionID
        defer { isSubmitting = false }
        do {
            if let id = context.reviewID {
                let result = try await service.update(id: id, request: patch)
                guard session == store.sessionID else { return false }
                store.changed(listingID: context.listingID, review: result)
            } else if let bookingID = ReviewValidation.text(context.bookingID) {
                let result = try await service.create(
                    bookingID: bookingID,
                    request: CreateReviewRequest(
                        rating: rating,
                        title: title,
                        comment: comment
                    )
                )
                guard session == store.sessionID else { return false }
                // POST has no author: invalidate and fetch public/profile lists separately.
                store.changed(listingID: context.listingID, review: result)
            } else {
                throw ReviewInputError.creationUnavailable
            }
            if let slug = ReviewValidation.text(context.slug) {
                await store.refreshRating(
                    listingID: context.listingID,
                    slug: slug,
                    locale: locale,
                    service: service
                )
            }
            return true
        } catch is CancellationError { return false } catch {
            duplicate = ReviewErrorMessage.isDuplicate(error)
            fieldErrors = (error as? APIRequestFailure)?.fieldErrors ?? [:]
            self.error = ReviewErrorMessage.text(error)
            return false
        }
    }
}
