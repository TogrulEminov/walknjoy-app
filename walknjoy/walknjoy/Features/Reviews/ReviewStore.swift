import Foundation
import Observation

/// Session-scoped invalidation shared by details, review lists and listing cards.
@MainActor @Observable
final class ReviewStore {
    private(set) var revision = 0
    private(set) var ownReviews: [String: MyReview] = [:]
    private var ratings: [String: Rating] = [:]
    private var invalidatedRatings: Set<String> = []
    private(set) var sessionID = UUID()
    private var ratingGenerations: [String: UUID] = [:]

    func rating(for listingID: String, fallback: Rating?) -> Rating? {
        if let rating = ratings[listingID] { return rating }
        return invalidatedRatings.contains(listingID) ? nil : fallback
    }
    func remember(_ reviews: [MyReview]) {
        for review in reviews { ownReviews[review.listingId] = review }
    }
    func changed(listingID: String, review: MyReview?) {
        ownReviews[listingID] = review
        ratings[listingID] = nil
        invalidatedRatings.insert(listingID)
        ratingGenerations[listingID] = UUID()
        revision += 1
    }
    func refreshRating(listingID: String, slug: String, locale: String, service: any ReviewServiceProtocol) async {
        let session = sessionID
        let generation = ratingGenerations[listingID]
        do {
            let rating = try await service.rating(slug: slug, locale: locale)
            guard session == sessionID, generation == ratingGenerations[listingID] else { return }
            ratings[listingID] = rating
            invalidatedRatings.remove(listingID)
        } catch {
            // Keep a stale aggregate hidden. A later list/detail refresh can retry.
        }
    }
    func reset() {
        sessionID = UUID()
        ownReviews = [:]; ratings = [:]; invalidatedRatings = []; ratingGenerations = [:]
        revision += 1
    }
}
