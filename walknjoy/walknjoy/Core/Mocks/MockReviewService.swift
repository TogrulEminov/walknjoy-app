import Foundation

@MainActor
final class MockReviewService: ReviewServiceProtocol {
    func reviews(
        slug: String,
        page: Int,
        limit: Int,
        sort: ReviewSort,
        locale: String
    ) async throws -> PaginationPage<PublicReview> {
        let reviews = [
            PublicReview(
                id: "1",
                rating: 5,
                title: "Amazing Experience!",
                comment:
                    "Absolutely loved everything about this place. Highly recommend!",
                createdAt: Date(),
                updatedAt: Date(),
                author: .init(id: "u1", firstName: "John", avatarFile: nil)
            ),
            PublicReview(
                id: "2",
                rating: 4,
                title: "Very Good",
                comment: "Great value for money and friendly staff.",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400),
                author: .init(id: "u2", firstName: "Jane", avatarFile: nil)
            ),
            PublicReview(
                id: "3",
                rating: 3,
                title: "Average",
                comment: "It was okay, but could be better.",
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-172800),
                author: .init(id: "u3", firstName: "Bob", avatarFile: nil)
            ),
        ]
        let total = reviews.count
        let totalPages = Int(ceil(Double(total) / Double(limit)))
        return PaginationPage(
            items: reviews,
            meta: .init(
                page: page,
                limit: limit,
                total: total,
                totalPages: totalPages
            )
        )
    }

    func mine(page: Int, limit: Int) async throws -> PaginationPage<MyReview> {
        let reviews = [
            MyReview(
                id: "r1",
                listingId: "l1",
                listing: .init(
                    id: "l1",
                    title: "Luxury Villa",
                    slug: "luxury-villa"
                ),
                rating: 5,
                title: "Perfect stay",
                comment: "The villa was stunning.",
                status: .published,
                createdAt: Date(),
                updatedAt: Date()
            ),
            MyReview(
                id: "r2",
                listingId: "l2",
                listing: .init(
                    id: "l2",
                    title: "City Apartment",
                    slug: "city-apartment"
                ),
                rating: 4,
                title: "Good location",
                comment: "Right in the heart of the city.",
                status: .published,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)
            ),
        ]
        let total = reviews.count
        let totalPages = Int(ceil(Double(total) / Double(limit)))
        return PaginationPage(
            items: reviews,
            meta: .init(
                page: page,
                limit: limit,
                total: total,
                totalPages: totalPages
            )
        )
    }

    func create(bookingID: String, request: CreateReviewRequest) async throws -> CreatedReview {
        CreatedReview(id: UUID().uuidString, listingId: "l1", bookingId: bookingID, listing: .init(id: "l1", title: "Preview Listing", slug: "preview-listing"), rating: request.rating, title: request.title, comment: request.comment, status: .published, createdAt: Date(), updatedAt: Date())
    }

    func update(id: String, request: UpdateReviewRequest) async throws
        -> MyReview
    {
        return MyReview(
            id: id,
            listingId: "l1",
            listing: .init(
                id: "l1",
                title: "Updated Listing",
                slug: "updated-listing"
            ),
            rating: request.rating ?? 5,
            title: "Updated Title",
            comment: "Updated Comment",
            status: .published,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func delete(id: String) async throws {
        // Mock delete - do nothing
    }

    func rating(slug: String, locale: String) async throws -> Rating {
        if let rating = MockTravelData.listings.first(where: { $0.slug == slug })?.rating {
            return rating
        }
        return Rating(average: 4.8, count: 63)
    }

    func listing(slug: String, locale: String) async throws -> PublicListing {
        if let listing = MockTravelData.listings.first(where: { $0.slug == slug }) {
            return listing
        }
        return PublicListing(
            id: "l1",
            type: .stay,
            title: "Mock Listing",
            slug: slug,
            shortDescription: "This is a mock listing description",
            basePrice: 100,
            currency: Currency.USD.rawValue,
            location: .init(
                countryCode: "AZ",
                city: "Mock City",
                addressLine: "Mock Street 123"
            ),
            rating: Rating(average: 4.5, count: 120)
        )
    }
}
