import Foundation

nonisolated enum ProviderPatchValue<Value: Encodable> {
    case omitted, null
    case value(Value)
    var isOmitted: Bool { if case .omitted = self { true } else { false } }
}
nonisolated extension KeyedEncodingContainer {
    fileprivate mutating func encodePatch<T>(
        _ value: ProviderPatchValue<T>,
        forKey key: Key
    ) throws {
        switch value {
        case .omitted: break
        case .null: try encodeNil(forKey: key)
        case .value(let value): try encode(value, forKey: key)
        }
    }
}

nonisolated struct ProviderLocationRequest: Encodable {
    var locale: ListingLocale
    var cityId: String?
    var latitude: Double?
    var longitude: Double?
    var district: ProviderPatchValue<String> = .omitted
    var addressLine: ProviderPatchValue<String> = .omitted
    private enum CodingKeys: String, CodingKey {
        case locale, cityId, latitude, longitude, district, addressLine
    }
    func encode(to encoder: Encoder) throws {
        if (cityId == nil) != (latitude == nil)
            || (latitude == nil) != (longitude == nil)
        {
            throw ListingInputError.invalidRequiredFields
        }
        if let latitude, !(-90...90).contains(latitude) {
            throw ListingInputError.invalidRequiredFields
        }
        if let longitude, !(-180...180).contains(longitude) {
            throw ListingInputError.invalidRequiredFields
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(cityId, forKey: .cityId)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encodePatch(district, forKey: .district)
        try c.encodePatch(addressLine, forKey: .addressLine)
    }
}

nonisolated struct CreateListingRequest: Encodable {
    var type: ListingType
    var categoryId: String?
    var basePrice: Decimal
    var currency: ProviderCurrency
    var locale: ListingLocale
    var title: String
    var description: String
    var slug: String?
    var shortDescription: String?
    var location: ProviderLocationRequest
    private enum CodingKeys: String, CodingKey {
        case type, categoryId, basePrice, currency, locale, title, description,
            slug, shortDescription, location
    }
    func encode(to encoder: Encoder) throws {
        guard title.listingNonBlank != nil, title.count <= 200,
            description.listingNonBlank != nil,
            description.count <= 5000, (shortDescription?.count ?? 0) <= 300,
            basePrice >= 0
        else { throw ListingInputError.invalidRequiredFields }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encode(
            Double(truncating: basePrice as NSNumber),
            forKey: .basePrice
        )
        try c.encode(currency, forKey: .currency)
        try c.encode(locale, forKey: .locale)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(slug, forKey: .slug)
        try c.encodeIfPresent(shortDescription, forKey: .shortDescription)
        try c.encode(location, forKey: .location)
    }
}

nonisolated struct UpdateListingRequest: Encodable {
    var locale: ListingLocale?
    var title: String?
    var description: String?
    var slug: ProviderPatchValue<String> = .omitted
    var shortDescription: ProviderPatchValue<String> = .omitted
    var categoryId: ProviderPatchValue<String> = .omitted
    var basePrice: Decimal?
    var currency: ProviderCurrency?
    var location: ProviderLocationRequest?
    private enum CodingKeys: String, CodingKey {
        case locale, title, description, slug, shortDescription, categoryId,
            basePrice, currency, location
    }
    func encode(to encoder: Encoder) throws {
        if locale != nil || title != nil || description != nil
            || !slug.isOmitted || !shortDescription.isOmitted
        {
            guard locale != nil
            else { throw ListingInputError.invalidRequiredFields }
        }
        if let title, title.listingNonBlank == nil || title.count > 200 {
            throw ListingInputError.invalidRequiredFields
        }
        if let description, description.listingNonBlank == nil || description.count > 5000 {
            throw ListingInputError.invalidRequiredFields
        }
        guard
            locale != nil || !categoryId.isOmitted || basePrice != nil
                || currency != nil || location != nil
        else { throw ListingInputError.invalidRequiredFields }
        if location != nil && locale == nil {
            throw ListingInputError.invalidRequiredFields
        }
        if let amount = basePrice, amount < 0 {
            throw ListingInputError.invalidRequiredFields
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(locale, forKey: .locale)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodePatch(slug, forKey: .slug)
        try c.encodePatch(shortDescription, forKey: .shortDescription)
        try c.encodePatch(categoryId, forKey: .categoryId)
        if let basePrice {
            try c.encode(
                Double(truncating: basePrice as NSNumber),
                forKey: .basePrice
            )
        }
        try c.encodeIfPresent(currency, forKey: .currency)
        try c.encodeIfPresent(location, forKey: .location)
    }
}

nonisolated struct ProviderMediaRequest: Encodable {
    let fileId: String
    let altText: String?
}

nonisolated enum ProviderListingValidation {
    static func price(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard
            normalized.range(
                of: #"^\d+(\.\d{1,2})?$"#,
                options: .regularExpression
            ) != nil
        else { return nil }
        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
    static func translation(
        title: String,
        description: String,
        slug: String,
        shortDescription: String
    ) -> Bool {
        title.listingNonBlank != nil && title.count <= 200
            && description.listingNonBlank != nil && description.count <= 5000
            && shortDescription.count <= 300
            && (slug.isEmpty
                || (slug.count <= 200
                    && slug.range(
                        of: #"^[a-z0-9]+(-[a-z0-9]+)*$"#,
                        options: .regularExpression
                    ) != nil))
    }
}

nonisolated struct ProviderPriceUpdateRequest: Encodable {
    let basePrice: Decimal
    let currency: ProviderCurrency
    private enum CodingKeys: String, CodingKey { case basePrice, currency }
    func encode(to encoder: Encoder) throws {
        guard basePrice >= 0 else {
            throw ListingInputError.invalidRequiredFields
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(
            Double(truncating: basePrice as NSNumber),
            forKey: .basePrice
        )
        try c.encode(currency, forKey: .currency)
    }
}
