import Foundation

struct ListingMedia: Decodable, Identifiable, Equatable {
    let id: String
    let type: String
    let url: String
    let isCover: Bool
    let order: Int

    init(id: String, type: String, url: String, isCover: Bool, order: Int) {
        self.id = id
        self.type = type
        self.url = url
        self.isCover = isCover
        self.order = order
    }
}

struct Listing: Decodable, Identifiable, Equatable {
    let id: String
    let type: ListingType
    let category: CategoryModel?
    let location: ListingLocation?
    let basePrice: Decimal
    let currency: String
    let status: ListingStatus?
    let title: String?
    let slug: String?
    let shortDescription: String?
    let description: String?
    let media: [ListingMedia]
    let amenities: [AmenityModel]
    let details: ListingDetails?
    let rating: Rating?
    let isFavorite: Bool

    init(
        id: String,
        type: ListingType,
        category: CategoryModel?,
        location: ListingLocation?,
        basePrice: Decimal,
        currency: String,
        status: ListingStatus?,
        title: String?,
        slug: String?,
        shortDescription: String?,
        description: String?,
        media: [ListingMedia],
        amenities: [AmenityModel],
        details: ListingDetails?,
        rating: Rating?,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.type = type
        self.category = category
        self.location = location
        self.basePrice = basePrice
        self.currency = currency
        self.status = status
        self.title = title
        self.slug = slug
        self.shortDescription = shortDescription
        self.description = description
        self.media = media
        self.amenities = amenities
        self.details = details
        self.rating = rating
        self.isFavorite = isFavorite
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, category, location, basePrice, currency, status
        case title, slug, shortDescription, description, media, amenities,
            details, rating, isFavorite
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        rating = try c.decodeIfPresent(Rating.self, forKey: .rating)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        type = try c.decode(ListingType.self, forKey: .type)
        category = try c.decodeIfPresent(CategoryModel.self, forKey: .category)
        location = try c.decodeIfPresent(
            ListingLocation.self,
            forKey: .location
        )
        if let text = try? c.decode(String.self, forKey: .basePrice),
            let value = Decimal(
                string: text,
                locale: Locale(identifier: "en_US_POSIX")
            )
        {
            basePrice = value
        } else {
            basePrice = try c.decode(Decimal.self, forKey: .basePrice)
        }
        currency = try c.decode(String.self, forKey: .currency)
        status = try c.decodeIfPresent(ListingStatus.self, forKey: .status)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        shortDescription = try c.decodeIfPresent(
            String.self,
            forKey: .shortDescription
        )
        description = try c.decodeIfPresent(String.self, forKey: .description)
        media = try c.decodeIfPresent([ListingMedia].self, forKey: .media) ?? []
        amenities =
            try c.decodeIfPresent([AmenityModel].self, forKey: .amenities) ?? []
        details =
            try c.decodeNilOrMissing(.details)
            ? nil
            : ListingDetails.decode(
                type: type,
                from: c.superDecoder(forKey: .details)
            )
    }

}

extension KeyedDecodingContainer {
    fileprivate func decodeNilOrMissing(_ key: Key) throws -> Bool {
        try !contains(key) || decodeNil(forKey: key)
    }
}
