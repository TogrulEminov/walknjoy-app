import Foundation
import Observation

enum ReviewServiceFactory {
    static var makeDefault: () -> any ReviewServiceProtocol = { ReviewService() }
}

@MainActor @Observable
final class ListingReviewsViewModel {
    let pagination = PaginationController<PublicReview>()
    let service: any ReviewServiceProtocol
    let slug: String
    let locale: String
    var sort: ReviewSort = .newest

    init(
        slug: String,
        locale: String,
        service: (any ReviewServiceProtocol)? = nil
    ) {
        self.slug = slug
        self.locale = locale
        self.service = service ?? ReviewServiceFactory.makeDefault()
    }

    private(set) var checkingBookings = false
    private(set) var relatedBookings: [BookingsModel] = []

    func eligibleBookings(listingID: String, bookingService: any BookingServiceProtocol, store: ReviewStore) async throws -> [BookingsModel] {
        guard !checkingBookings else { return [] }
        checkingBookings = true
        defer { checkingBookings = false }
        let session = store.sessionID
        let bookings = try await bookingService.getCustomerBookings()
        var reviews: [MyReview] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let result = try await service.mine(page: page, limit: 20)
            reviews.append(contentsOf: result.items)
            if !result.hasNextPage(currentPage: page, limit: 20) || result.items.isEmpty { break }
            page += 1
        }
        guard session == store.sessionID else { throw CancellationError() }
        relatedBookings = bookings.filter { $0.listing.id == listingID }
        store.remember(reviews)
        let matching = reviews.filter { $0.listingId == listingID }
        // Never guess which reservation owns a review when the API omits its booking ID.
        guard matching.allSatisfy({ ReviewValidation.text($0.bookingId) != nil }) else {
            throw ReviewEligibilityError.missingBookingID
        }
        let reviewed = Set(matching.compactMap(\.bookingId))
        return bookings.filter {
            $0.listing.id == listingID && $0.status.uppercased() == "COMPLETED" && !reviewed.contains($0.id)
        }
    }

    func refresh() async {
        let sort = sort
        let slug = slug
        let service = service
        let locale = locale
        await pagination.refresh { page, limit in
            try await service.reviews(
                slug: slug,
                page: page,
                limit: limit,
                sort: sort,
                locale: locale
            )
        }
    }
}

enum ReviewEligibilityError: LocalizedError {
    case missingBookingID
    var errorDescription: String? { String(localized: "reviews.missingBookingID") }
}
