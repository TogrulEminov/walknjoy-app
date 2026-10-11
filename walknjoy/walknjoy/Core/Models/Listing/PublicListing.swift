import Foundation

enum Currency: String, Codable, CaseIterable {
    case AZN, USD, EUR
}

enum MediaType: String, Codable {
    case image
    case video
    case panorama360 = "panorama_360"
}

struct ListingCategory: Decodable, Hashable {
    let id: String
    let name: String
    let slug: String
}

struct CoverMedia: Decodable, Hashable {
    let type: MediaType
    let url: String
}

enum ListingCardDetails: Hashable {
    case stay(StayCardDetails?)
    case tour(TourCardDetails?)
    case activity(ActivityCardDetails?)
    case experience
}

struct StayCardDetails: Decodable, Hashable {
    let maxGuests: Int
}

struct TourCardDetails: Decodable, Hashable {
    let durationMinutes: Int?
}

struct ActivityCardDetails: Decodable, Hashable {
    let durationMinutes: Int?
}

struct PublicListing: Decodable, Identifiable, Hashable {
    let id: String
    let type: ListingType
    let title: String
    let slug: String
    let shortDescription: String?
    let basePrice: Decimal
    let hasPrice: Bool
    let currency: String
    let isFeatured: Bool
    let category: ListingCategory?
    let location: ListingLocation?
    let coverMedia: CoverMedia?
    let rating: Rating
    let isFavorite: Bool
    let details: ListingCardDetails

    init(
        id: String,
        type: ListingType,
        title: String,
        slug: String,
        shortDescription: String? = nil,
        basePrice: Decimal,
        currency: String,
        isFeatured: Bool = false,
        category: ListingCategory? = nil,
        location: ListingLocation? = nil,
        coverMedia: CoverMedia? = nil,
        rating: Rating = Rating(average: nil, count: 0),
        isFavorite: Bool = false,
        details: ListingCardDetails = .experience
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.slug = slug
        self.shortDescription = shortDescription
        self.basePrice = basePrice
        self.hasPrice = true
        self.currency = currency
        self.isFeatured = isFeatured
        self.category = category
        self.location = location
        self.coverMedia = coverMedia
        self.rating = rating
        self.isFavorite = isFavorite
        self.details = details
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, title, slug, shortDescription, basePrice, currency
        case isFeatured, category, location, coverMedia, rating, isFavorite, details, media
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ListingType.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        slug = try container.decodeIfPresent(String.self, forKey: .slug) ?? ""
        shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)
        hasPrice = try container.contains(.basePrice) && !container.decodeNil(forKey: .basePrice)
        if let value = try? container.decode(String.self, forKey: .basePrice),
           let decimal = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) {
            basePrice = decimal
        } else {
            basePrice = try container.decodeIfPresent(Decimal.self, forKey: .basePrice) ?? 0
        }
        currency = try container.decode(String.self, forKey: .currency)
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        category = try container.decodeIfPresent(ListingCategory.self, forKey: .category)
        location = try container.decodeIfPresent(ListingLocation.self, forKey: .location)
        if let cover = try container.decodeIfPresent(CoverMedia.self, forKey: .coverMedia) {
            coverMedia = cover
        } else {
            let media = try container.decodeIfPresent([CardMedia].self, forKey: .media) ?? []
            let cover = media.first(where: \.isCover) ?? media.sorted { $0.order < $1.order }.first
            coverMedia = cover.map { CoverMedia(type: $0.type, url: $0.url) }
        }
        rating = try container.decodeIfPresent(Rating.self, forKey: .rating) ?? Rating(average: nil, count: 0)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false

        switch type {
        case .stay:
            details = .stay(try container.decodeIfPresent(StayCardDetails.self, forKey: .details))
        case .tour:
            details = .tour(try container.decodeIfPresent(TourCardDetails.self, forKey: .details))
        case .activity:
            details = .activity(try container.decodeIfPresent(ActivityCardDetails.self, forKey: .details))
        case .experience:
            details = .experience
        }
    }
}

typealias ListingResponse = PublicListing

private struct CardMedia: Decodable {
    let type: MediaType
    let url: String
    let isCover: Bool
    let order: Int
}
