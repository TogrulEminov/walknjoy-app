import Foundation

nonisolated protocol ReviewServiceProtocol {
    func reviews(
        slug: String,
        page: Int,
        limit: Int,
        sort: ReviewSort,
        locale: String
    ) async throws -> PaginationPage<PublicReview>
    func mine(page: Int, limit: Int) async throws -> PaginationPage<MyReview>
    func create(bookingID: String, request: CreateReviewRequest) async throws
        -> CreatedReview
    func update(id: String, request: UpdateReviewRequest) async throws
        -> MyReview
    func delete(id: String) async throws
    func rating(slug: String, locale: String) async throws -> Rating
    func listing(slug: String, locale: String) async throws -> PublicListing
}

nonisolated final class ReviewService: ReviewServiceProtocol {
    private let network: NetworkingService
    init(network: NetworkingService? = nil) {
        self.network = network ?? DefaultNetworkService()
    }

    func reviews(
        slug: String,
        page: Int,
        limit: Int,
        sort: ReviewSort,
        locale: String
    ) async throws -> PaginationPage<PublicReview> {
        let response: ApiResponse<[PublicReview]> = try await network.request(
            enpoint: ReviewEndpoint.listing(
                slug: slug,
                page: page,
                limit: limit,
                sort: sort,
                locale: locale
            ),
            responseType: ApiResponse<[PublicReview]>.self
        )
        guard response.success, let data = response.data,
            let meta = response.meta
        else { throw NetworkError.invalidResponse }
        return PaginationPage(items: data, meta: meta)
    }
    func mine(page: Int, limit: Int) async throws -> PaginationPage<MyReview> {
        let response: ApiResponse<[MyReview]> = try await network.request(
            enpoint: ReviewEndpoint.mine(page: page, limit: limit),
            responseType: ApiResponse<[MyReview]>.self
        )
        guard response.success, let data = response.data,
            let meta = response.meta
        else { throw NetworkError.invalidResponse }
        return PaginationPage(items: data, meta: meta)
    }
    func create(bookingID: String, request: CreateReviewRequest) async throws
        -> CreatedReview
    {
        try await value(
            ReviewEndpoint.create(bookingID: bookingID, request: request),
            as: CreatedReview.self
        )
    }
    func update(id: String, request: UpdateReviewRequest) async throws
        -> MyReview
    {
        guard request.hasChanges else { throw ReviewInputError.unchanged }
        return try await value(
            ReviewEndpoint.update(id: id, request: request),
            as: MyReview.self
        )
    }
    func delete(id: String) async throws {
        struct Deleted: Decodable { let deleted: Bool }
        let result = try await value(
            ReviewEndpoint.delete(id: id),
            as: Deleted.self
        )
        guard result.deleted else { throw NetworkError.invalidResponse }
    }
    func rating(slug: String, locale: String) async throws -> Rating {

        struct Aggregate: Decodable { let rating: Rating }
        return try await value(
            ListingEndpoint.getListing(slug: slug, locale: locale),
            as: Aggregate.self
        ).rating
    }
    func listing(slug: String, locale: String) async throws -> PublicListing {
        try await value(
            ListingEndpoint.getListing(slug: slug, locale: locale),
            as: PublicListing.self
        )
    }
    private func value<T: Decodable>(_ endpoint: any Endpoint, as type: T.Type)
        async throws -> T
    {
        let response = try await network.request(
            enpoint: endpoint,
            responseType: ApiResponse<T>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }
}

nonisolated enum ReviewErrorMessage {
    static func isDuplicate(_ error: Error) -> Bool {
        if let failure = error as? APIRequestFailure {
            return failure.error.code == "REVIEW_ALREADY_EXISTS"
        }
        if case NetworkError.reviewAlreadyExists = error { return true }
        return false
    }
    static func text(_ error: Error) -> String {
        if isDuplicate(error) {
            return String(localized: "reviews.bookingAlreadyReviewed")
        }
        if let failure = error as? APIRequestFailure,
            failure.error.code == "REVIEW_BOOKING_NOT_COMPLETED"
        {
            return String(localized: "reviews.bookingNotCompleted")
        }
        return error.localizedDescription
    }
}
