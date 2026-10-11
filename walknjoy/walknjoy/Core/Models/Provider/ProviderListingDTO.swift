import Foundation

struct ProviderListingActions: Codable, Equatable {
    let canEdit: Bool
    let canSubmit: Bool
    let canArchive: Bool
}

struct ProviderListingCardDTO: Codable, Identifiable, Equatable {
    struct Cover: Codable, Equatable {
        let id: String
        let type: String
        let url: String
    }
    struct Category: Codable, Equatable {
        let id: String
        let name: String
        let slug: String
    }
    struct Location: Codable, Equatable {
        let cityId: String
        let city: String?
        let countryCode: String
    }
    struct Rating: Codable, Equatable {
        let average: Double?
        let count: Int
    }
    let id: String
    let type: ListingType
    let status: ListingStatus
    let title: String?
    let slug: String?
    let coverMedia: Cover?
    let category: Category?
    let location: Location?
    let basePrice: String
    let currency: String
    let rating: Rating
    let actions: ProviderListingActions
    let updatedAt: String
    var price: Decimal? {
        Decimal(string: basePrice, locale: Locale(identifier: "en_US_POSIX"))
    }
}

struct ProviderListingEditorDTO: Codable, Identifiable {
    struct Translation: Codable {
        let language: ListingLocale
        let title: String
        let slug: String
        let shortDescription: String?
        let description: String
    }
    struct Location: Codable {
        struct Translation: Codable {
            let language: ListingLocale
            let city: String
            let district: String?
            let addressLine: String?
        }
        let id: String
        let cityId: String
        let countryCode: String
        let latitude: Double
        let longitude: Double
        let translations: [Translation]
    }
    struct Media: Codable, Identifiable {
        let id: String
        let type: String
        let url: String
        let fileId: String
        let mimeType: String
        let sizeBytes: Int
        let thumbnailUrl: String?
        let altText: String?
        let order: Int
        let isCover: Bool
    }
    let id: String
    let providerId: String
    let categoryId: String?
    let type: ListingType
    let status: ListingStatus
    let basePrice: String
    let currency: String
    let isFeatured: Bool
    let rejectionReason: String?
    let translations: [Translation]
    let location: Location?
    let media: [Media]
    let createdAt: String
    let updatedAt: String
    var price: Decimal? { Decimal(string: basePrice, locale: Locale(identifier: "en_US_POSIX")) }
}

enum ProviderCurrency: String, Codable { case AZN, USD, EUR }

extension ListingType {
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let value = try c.decode(String.self).lowercased()
        guard let type = Self(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported listing type")
        }
        self = type
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}

enum ProviderListingSort: String, CaseIterable, Identifiable {
    case newest
    case priceAscending = "price_asc"
    case priceDescending = "price_desc"
    case featured
    var id: Self { self }
}

struct ProviderListingsQuery: Hashable {
    var page = 1
    var limit = 20
    var locale: ListingLocale = .az
    var type: ListingType?
    var status: ListingStatus?
    var categoryId: String?
    var q = ""
    var sort: ProviderListingSort = .newest

    var isFiltered: Bool {
        type != nil || status != nil || categoryId != nil
            || q.listingNonBlank != nil
    }
    func queryItems() -> [URLQueryItem] {
        let values: [(String, String?)] = [
            ("page", String(max(1, page))),
            ("limit", String(min(100, max(1, limit)))),
            ("locale", locale.rawValue), ("type", type?.rawValue),
            ("status", status?.rawValue.uppercased()),
            ("categoryId", categoryId?.listingNonBlank),
            ("q", q.listingNonBlank.map { String($0.prefix(150)) }),
            ("sort", sort.rawValue),
        ]
        return values.compactMap { name, value in
            value.map { URLQueryItem(name: name, value: $0) }
        }
    }
}

struct ProviderListingDetailsDTO: Decodable {
    struct Amenity: Decodable { let id: String }
    let type: ListingType
    let details: ListingDetails?
    let amenities: [Amenity]
    private enum CodingKeys: String, CodingKey {
        case type, details, amenities
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(ListingType.self, forKey: .type)
        details =
            try c.decodeNil(forKey: .details)
            ? nil
            : ListingDetails.decode(
                type: type,
                from: c.superDecoder(forKey: .details)
            )
        amenities = try c.decode([Amenity].self, forKey: .amenities)
    }
}
