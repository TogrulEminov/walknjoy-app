import Foundation

enum ListingLocale: String, Codable, CaseIterable, Identifiable {
    case az, en, ru
    var id: String { rawValue }
 
    static var available: [ListingLocale] {
        AppLanguage.allCases.compactMap { ListingLocale(rawValue: $0.rawValue) }
    }

    var title: String {
        AppLanguage(rawValue: rawValue)?.title ?? rawValue.uppercased()
    }
}

extension String {
    var listingNonBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

struct ListingLocationInput: Encodable {
    var cityId: String
    var latitude: Double
    var longitude: Double
    var locale: ListingLocale
    var district: String?
    var addressLine: String?

    private enum CodingKeys: String, CodingKey { case cityId, latitude, longitude, locale, district, addressLine }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(cityId, forKey: .cityId)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(district?.listingNonBlank, forKey: .district)
        try c.encodeIfPresent(addressLine?.listingNonBlank, forKey: .addressLine)
    }
}

struct CreateListingInput: Encodable {
    var type: ListingType
    var categoryId: String
    var basePrice: Decimal
    var currency: String
    var locale: ListingLocale
    var title: String
    var description: String
    var slug: String?
    var shortDescription: String?
    var location: ListingLocationInput

    private enum CodingKeys: String, CodingKey {
        case type, categoryId, basePrice, currency, locale, title, description, slug, shortDescription, location
    }
    func encode(to encoder: Encoder) throws {
        guard title.listingNonBlank != nil, description.listingNonBlank != nil,
              categoryId.listingNonBlank != nil, location.cityId.listingNonBlank != nil,
              basePrice >= 0, currency.listingNonBlank != nil, location.locale == locale,
              (-90...90).contains(location.latitude), (-180...180).contains(location.longitude) else {
            throw ListingInputError.invalidRequiredFields
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encode(categoryId, forKey: .categoryId)
        try c.encode(basePrice, forKey: .basePrice)
        try c.encode(currency, forKey: .currency)
        try c.encode(locale, forKey: .locale)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(slug?.listingNonBlank, forKey: .slug)
        try c.encodeIfPresent(shortDescription?.listingNonBlank, forKey: .shortDescription)
        try c.encode(location, forKey: .location)
    }
}

struct UpdateListingInput: Encodable {
    var locale: ListingLocale
    var title: String? = nil
    var description: String? = nil
    var slug: String? = nil
    var shortDescription: String? = nil
    var categoryId: String? = nil
    var basePrice: Decimal? = nil
    var currency: String? = nil
    var location: ListingLocationInput? = nil

    private enum CodingKeys: String, CodingKey {
        case locale, title, description, slug, shortDescription, categoryId, basePrice, currency, location
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(title?.listingNonBlank, forKey: .title)
        try c.encodeIfPresent(description?.listingNonBlank, forKey: .description)
        try c.encodeIfPresent(slug?.listingNonBlank, forKey: .slug)
        try c.encodeIfPresent(shortDescription?.listingNonBlank, forKey: .shortDescription)
        try c.encodeIfPresent(categoryId?.listingNonBlank, forKey: .categoryId)
        try c.encodeIfPresent(basePrice, forKey: .basePrice)
        try c.encodeIfPresent(currency?.listingNonBlank, forKey: .currency)
        try c.encodeIfPresent(location, forKey: .location)
    }
}

struct ListingDetailsInput: Encodable {
    let details: ListingDetails
    let amenityIds: [String]
    private enum CodingKeys: String, CodingKey { case amenityIds }
    func encode(to encoder: Encoder) throws {
        switch details {
        case .stay(var value):
            value.checkInFrom = value.checkInFrom?.listingNonBlank
            value.checkInUntil = value.checkInUntil?.listingNonBlank
            value.checkOutFrom = value.checkOutFrom?.listingNonBlank
            value.checkOutUntil = value.checkOutUntil?.listingNonBlank
            try value.encode(to: encoder)
        case .tour(var value):
            value.meetingPoint = value.meetingPoint?.listingNonBlank
            value.languages = value.languages.compactMap(\.listingNonBlank)
            try value.encode(to: encoder)
        case .activity(var value):
            value.difficulty = value.difficulty?.listingNonBlank
            try value.encode(to: encoder)
        case .experience(let value): try value.encode(to: encoder)
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(amenityIds, forKey: .amenityIds)
    }
}

enum ListingInputError: LocalizedError {
    case invalidRequiredFields
    var errorDescription: String? { String(localized: "listing.validation.required") }
}
