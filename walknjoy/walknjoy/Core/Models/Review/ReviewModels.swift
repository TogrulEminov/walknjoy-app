import Foundation

struct PublicReview: Decodable, Identifiable {
    struct Author: Decodable {
        let id: String
        let firstName: String
        let avatarFile: UploadedFile?
    }
    let id: String
    let rating: Int
    let title: String?
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
    let author: Author
    var verified: Bool? = nil
}

struct MyReview: Decodable, Identifiable {
    struct ListingSummary: Decodable {
        let id: String
        let title: String?
        let slug: String?
    }
    enum Status: String, Decodable {
        case published = "PUBLISHED"
        case hidden = "HIDDEN"
    }
    let id: String
    let listingId: String
    var bookingId: String? = nil
    let listing: ListingSummary
    let rating: Int
    let title: String?
    let comment: String?
    let status: Status
    let createdAt: Date
    let updatedAt: Date
}

typealias CreatedReview = MyReview

enum ReviewSort: String, CaseIterable, Identifiable {
    case newest, oldest
    case ratingHigh = "rating_high"
    case ratingLow = "rating_low"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .newest: String(localized: "reviews.sort.newest")
        case .oldest: String(localized: "reviews.sort.oldest")
        case .ratingHigh: String(localized: "reviews.sort.ratingHigh")
        case .ratingLow: String(localized: "reviews.sort.ratingLow")
        }
    }
}

enum ReviewValidation {
    static func text(_ value: String?) -> String? {
        guard
            let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty
        else { return nil }
        return value
    }
    static func validate(rating: Int?, title: String?, comment: String?) throws
    {
        guard rating.map({ (1...5).contains($0) }) ?? true,
            (title?.count ?? 0) <= 120, (comment?.count ?? 0) <= 2000
        else {
            throw ReviewInputError.invalid
        }
    }
}

enum ReviewInputError: LocalizedError {
    case invalid, unchanged, creationUnavailable
    var errorDescription: String? {
        switch self {
        case .creationUnavailable:
            String(localized: "reviews.creationUnavailable")
        case .invalid: String(localized: "reviews.validation")
        case .unchanged: String(localized: "reviews.unchanged")
        }
    }
}

struct CreateReviewRequest: Encodable {
    let rating: Int
    let title: String?
    let comment: String?
    init(rating: Int, title: String?, comment: String?) throws {
        try ReviewValidation.validate(
            rating: rating,
            title: title,
            comment: comment
        )
        self.rating = rating
        self.title = ReviewValidation.text(title)
        self.comment = ReviewValidation.text(comment)
    }
}

enum ReviewTextChange: Equatable {
    case unchanged, clear
    case value(String)
    static func comparing(_ value: String, to original: String?) -> Self {
        let normalized = ReviewValidation.text(value)
        guard normalized != ReviewValidation.text(original) else {
            return .unchanged
        }
        return normalized.map(Self.value) ?? .clear
    }
}

struct UpdateReviewRequest: Encodable {
    let rating: Int?
    let title: ReviewTextChange
    let comment: ReviewTextChange
    var hasChanges: Bool {
        rating != nil || title != .unchanged || comment != .unchanged
    }
    private enum CodingKeys: String, CodingKey { case rating, title, comment }
    func encode(to encoder: Encoder) throws {
        guard hasChanges else { throw ReviewInputError.unchanged }
        let titleValue: String? =
            if case .value(let text) = title { text } else { nil }
        let commentValue: String? =
            if case .value(let text) = comment { text } else { nil }
        try ReviewValidation.validate(
            rating: rating,
            title: titleValue,
            comment: commentValue
        )
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(rating, forKey: .rating)
        for (key, change) in [(CodingKeys.title, title), (.comment, comment)] {
            switch change {
            case .unchanged: break
            case .clear: try container.encodeNil(forKey: key)
            case .value(let value):
                if let value = ReviewValidation.text(value) {
                    try container.encode(value, forKey: key)
                } else {
                    try container.encodeNil(forKey: key)
                }
            }
        }
    }
}

struct ReviewEditorContext: Identifiable {
    let listingID: String
    let slug: String?
    var bookingID: String? = nil
    var reviewID: String? = nil
    var rating: Int = 0
    var title: String? = nil
    var comment: String? = nil
    var id: String { reviewID ?? listingID }
    init(listingID: String, slug: String?, bookingID: String? = nil) {
        self.listingID = listingID
        self.slug = slug
        self.bookingID = bookingID
    }
    init(_ review: MyReview) {
        listingID = review.listingId
        slug = review.listing.slug
        reviewID = review.id
        rating = review.rating
        title = review.title
        comment = review.comment
    }
    init(_ review: PublicReview, listingID: String, slug: String) {
        self.listingID = listingID
        self.slug = slug
        reviewID = review.id
        rating = review.rating
        title = review.title
        comment = review.comment
    }
}
