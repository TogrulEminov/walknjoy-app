import Foundation
import Testing

@testable import walknjoy

@MainActor
struct ReviewContractTests {
    @Test func editorRequiresRatingAndBlocksUnchangedEdit() throws {
        let model = ReviewEditorViewModel(
            context: .init(
                listingID: "listing-1",
                slug: nil,
                bookingID: "booking-1"
            )
        )
        #expect(!model.canSubmit)
        model.rating = 5
        #expect(model.canSubmit)
        model.title = String(repeating: "a", count: 121)
        #expect(!model.canSubmit)
        let review = try JSONDecoder.apiDecoder.decode(
            MyReview.self,
            from: Data(customerJSON.utf8)
        )
        #expect(!ReviewEditorViewModel(context: .init(review)).canSubmit)
    }

    @Test func editorCreateSuccessUpdatesRelatedScreensThroughStore() async {
        let network = ReviewFixtureNetwork(responses: [
            "{\"success\":true,\"data\":\(customerJSON)}"
        ])
        let model = ReviewEditorViewModel(
            context: .init(
                listingID: "listing-1",
                slug: nil,
                bookingID: "booking-1"
            ),
            service: ReviewService(network: network)
        )
        model.rating = 5
        let store = ReviewStore()
        let saved = await model.submit(store: store, locale: "az")
        #expect(saved)
        #expect(store.revision == 1)
        #expect(store.ownReviews["review-1"]?.bookingId == "booking-1")
        #expect(!model.isSubmitting)
        #expect(model.error == nil)
    }

    @Test func editorDuplicateRefreshesHistoryAndBlocksAnotherCreate() async {
        let network = ReviewFixtureNetwork(responses: [
            "{\"success\":true,\"data\":[\(customerJSON)],\"meta\":{\"page\":1,\"limit\":20,\"total\":1,\"totalPages\":1}}"
        ])
        network.nextError = APIRequestFailure(
            error: ApiError(
                code: "REVIEW_ALREADY_EXISTS",
                message: "Already exists",
                details: nil
            )
        )
        let model = ReviewEditorViewModel(
            context: .init(
                listingID: "listing-1",
                slug: nil,
                bookingID: "booking-1"
            ),
            service: ReviewService(network: network)
        )
        model.rating = 5
        let store = ReviewStore()
        let saved = await model.submit(store: store, locale: "az")
        #expect(!saved)
        #expect(model.duplicate)
        #expect(!model.canSubmit)
        #expect(!model.isSubmitting)
        #expect(store.ownReviews["review-1"]?.bookingId == "booking-1")
        #expect(store.revision == 1)
        #expect(network.requestedPages == ["", "1"])
    }

    @Test func createOmitsBlankTextAndSendsOnlyAllowedFields() throws {
        let input = try CreateReviewRequest(
            rating: 5,
            title: "  \n",
            comment: " Razı qaldım. "
        )
        let body = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(input))
                as? [String: Any]
        )
        #expect(Set(body.keys) == ["rating", "comment"])
        #expect(body["rating"] as? Int == 5)
        #expect(body["comment"] as? String == "Razı qaldım.")
    }

    @Test func updateSendsExplicitNullAndOmitsUnchangedFields() throws {
        let input = UpdateReviewRequest(
            rating: nil,
            title: .clear,
            comment: .unchanged
        )
        let body = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(input))
                as? [String: Any]
        )
        #expect(Set(body.keys) == ["title"])
        #expect(body["title"] is NSNull)
        #expect(throws: (any Error).self) {
            try JSONEncoder().encode(
                UpdateReviewRequest(
                    rating: nil,
                    title: .unchanged,
                    comment: .unchanged
                )
            )
        }
    }

    @Test func inputRejectsInvalidRatingAndTextLengths() {
        for rating in [0, 6] {
            #expect(throws: (any Error).self) {
                try CreateReviewRequest(
                    rating: rating,
                    title: nil,
                    comment: nil
                )
            }
        }
        #expect(throws: (any Error).self) {
            try CreateReviewRequest(
                rating: 5,
                title: String(repeating: "a", count: 121),
                comment: nil
            )
        }
        #expect(throws: (any Error).self) {
            try CreateReviewRequest(
                rating: 5,
                title: nil,
                comment: String(repeating: "a", count: 2001)
            )
        }
    }

    @Test func customerDTODecodesNullableListingAndHiddenStatus() throws {
        let review = try JSONDecoder.apiDecoder.decode(
            MyReview.self,
            from: Data(customerJSON.utf8)
        )
        #expect(review.bookingId == "booking-1")
        #expect(review.listing.title == nil)
        #expect(review.listing.slug == nil)
        #expect(review.title == nil)
        #expect(review.comment == nil)
        #expect(review.status == .hidden)
    }

    @Test func publicDTODecodesVerifiedAuthorWithoutCustomerFields() throws {
        let json = """
            {"id":"public-1","rating":5,"title":null,"comment":null,
             "createdAt":"2026-10-13T10:00:00.000Z","updatedAt":"2026-10-13T10:00:00Z",
             "verified":true,"author":{"id":"user-1","firstName":"Emin","avatarFile":null}}
            """
        let review = try JSONDecoder.apiDecoder.decode(
            PublicReview.self,
            from: Data(json.utf8)
        )
        #expect(review.verified == true)
        #expect(review.author.firstName == "Emin")
    }

    @Test func endpointsUseCorrectMethodsAuthenticationAndSort() throws {
        let create = ReviewEndpoint.create(
            bookingID: "booking-1",
            request: try CreateReviewRequest(
                rating: 5,
                title: nil,
                comment: nil
            )
        )
        let request = try create.makeRequest()
        #expect(request.url?.path == "/api/v1/bookings/booking-1/review")
        #expect(request.httpMethod == "POST")
        #expect(create.requiresAuth)
        let mine = ReviewEndpoint.mine(page: 2, limit: 20, sort: .ratingLow)
        #expect(
            mine.queryItems?.first(where: { $0.name == "sort" })?.value
                == "rating_low"
        )
        #expect(mine.requiresAuth)
        #expect(
            ReviewEndpoint.update(
                id: "review-1",
                request: .init(
                    rating: 4,
                    title: .unchanged,
                    comment: .unchanged
                )
            ).method == .patch
        )
        #expect(ReviewEndpoint.delete(id: "review-1").method == .delete)
        #expect(
            !ReviewEndpoint.listing(
                slug: "test",
                page: 1,
                limit: 20,
                sort: .newest,
                locale: "az"
            ).requiresAuth
        )
    }

    @Test func historyChecksEveryPageBeforeConcludingAbsence() async throws {
        let network = ReviewFixtureNetwork(responses: [
            pageJSON(items: customerJSON, page: 1, totalPages: 2),
            pageJSON(
                items: customerJSON.replacingOccurrences(
                    of: "booking-1",
                    with: "booking-2"
                ).replacingOccurrences(of: "review-1", with: "review-2"),
                page: 2,
                totalPages: 2
            ),
        ])
        let history = try await ReviewService(network: network).allMine()
        #expect(history.map(\.bookingId) == ["booking-1", "booking-2"])
        #expect(network.requestedPages == ["1", "2"])
    }

    @Test func historyRejectsEmptyIntermediatePage() async {
        let service = ReviewService(
            network: ReviewFixtureNetwork(responses: [
                pageJSON(items: "", page: 1, totalPages: 2)
            ])
        )
        do {
            _ = try await service.allMine()
            Issue.record("Incomplete history must not be treated as no review")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test func storeKeepsSeparateReviewsForBookingsOfSameListing() throws {
        let first = try JSONDecoder.apiDecoder.decode(
            MyReview.self,
            from: Data(customerJSON.utf8)
        )
        let second = try JSONDecoder.apiDecoder.decode(
            MyReview.self,
            from: Data(
                customerJSON.replacingOccurrences(
                    of: "review-1",
                    with: "review-2"
                ).replacingOccurrences(of: "booking-1", with: "booking-2").utf8
            )
        )
        let store = ReviewStore()
        store.remember([first, second])
        #expect(store.ownReviews.count == 2)
        store.changed(
            listingID: first.listingId,
            review: nil,
            reviewID: first.id
        )
        #expect(store.ownReviews.count == 1)
        #expect(store.ownReviews[second.id]?.bookingId == "booking-2")
    }

    private var customerJSON: String {
        """
        {"id":"review-1","bookingId":"booking-1","listingId":"listing-1",
         "listing":{"id":"listing-1","title":null,"slug":null},"rating":5,
         "title":null,"comment":null,"status":"HIDDEN",
         "createdAt":"2026-10-13T10:00:00.000Z","updatedAt":"2026-10-13T10:00:00Z"}
        """
    }

    private func pageJSON(items: String, page: Int, totalPages: Int) -> String {
        """
        {"success":true,"data":[\(items)],"meta":{"page":\(page),"limit":20,"total":2,"totalPages":\(totalPages)}}
        """
    }
}

private nonisolated final class ReviewFixtureNetwork: NetworkingService {
    var responses: [String]
    var requestedPages: [String] = []
    var nextError: (any Error)?
    init(responses: [String]) { self.responses = responses }

    func request<T: Decodable>(enpoint: any Endpoint, responseType: T.Type)
        async throws -> T
    {
        requestedPages.append(
            enpoint.queryItems?.first(where: { $0.name == "page" })?.value ?? ""
        )
        if let error = nextError {
            nextError = nil
            throw error
        }
        guard !responses.isEmpty else { throw NetworkError.invalidResponse }
        return try JSONDecoder.apiDecoder.decode(
            responseType,
            from: Data(responses.removeFirst().utf8)
        )
    }
    func requestData(enpoint: any Endpoint) async throws -> Data {
        throw NetworkError.invalidResponse
    }
}
