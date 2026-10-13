import Foundation
import Observation

@MainActor @Observable
final class ReviewStore {
    private(set) var revision = 0
    private(set) var ownReviews: [String: MyReview] = [:]
    private(set) var ratingStates: [String: LoadState<Rating>] = [:]
    private var ratings: [String: Rating] = [:]
    private var invalidatedRatings: Set<String> = []
    private(set) var sessionID = UUID()
    private var ratingGenerations: [String: UUID] = [:]

    func rating(for listingID: String, fallback: Rating?) -> Rating? {
        if let rating = ratings[listingID] { return rating }
        return invalidatedRatings.contains(listingID) ? nil : fallback
    }
    func ratingState(for listingID: String) -> LoadState<Rating> {
        ratingStates[listingID] ?? .idle
    }
    func remember(_ reviews: [MyReview]) {
        for review in reviews { ownReviews[review.id] = review }
    }
    func changed(listingID: String, review: MyReview?, reviewID: String? = nil) {
        if let review { ownReviews[review.id] = review }
        else if let reviewID { ownReviews[reviewID] = nil }
        ratings[listingID] = nil
        ratingStates[listingID] = .idle
        invalidatedRatings.insert(listingID)
        ratingGenerations[listingID] = UUID()
        revision += 1
    }
    func refreshRating(
        listingID: String,
        slug: String,
        locale: String,
        service: any ReviewServiceProtocol
    ) async {
        let session = sessionID
        let generation = UUID()
        ratingGenerations[listingID] = generation
        let previousState = ratingState(for: listingID)
        ratingStates[listingID] = .loading
        do {
            let rating = try await service.rating(slug: slug, locale: locale)
            guard session == sessionID,
                generation == ratingGenerations[listingID]
            else { return }
            ratings[listingID] = rating
            invalidatedRatings.remove(listingID)
            ratingStates[listingID] = .loaded(rating)
        } catch is CancellationError {
            guard session == sessionID,
                generation == ratingGenerations[listingID]
            else { return }
            if case .loading = previousState {
                ratingStates[listingID] = .idle
            } else {
                ratingStates[listingID] = previousState
            }
        } catch {
            guard session == sessionID,
                generation == ratingGenerations[listingID]
            else { return }
            ratingStates[listingID] = .error(ReviewErrorMessage.text(error))
        }
    }
    func reset() {
        sessionID = UUID()
        ownReviews = [:]
        ratings = [:]
        ratingStates = [:]
        invalidatedRatings = []
        ratingGenerations = [:]
        revision += 1
    }
}
