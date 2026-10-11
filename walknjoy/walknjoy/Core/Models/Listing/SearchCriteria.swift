import Foundation

struct ListingSearchCriteria: Hashable {
    var locale = "az"
    var query = ""
    var type: ListingType?
    var categoryId: String?
    var destinationId: String?
    var destinationName: String?
    var city: String?
    var countryCode: String?
    var minPrice: Decimal? 
    var maxPrice: Decimal?
    var minRating: Int?
    var propertyType: String?
    var amenityIds: Set<String> = []
    var checkIn: Date?
    var checkOut: Date?
    var adults = 2
    var children = 0
    var dateFrom: Date?
    var dateTo: Date?
    var participants = 1
    var sort: ListingSort = .newest
    var page = 1
    var limit = 20

    mutating func resetFilters() {
        let preservedLocale = locale
        let preservedQuery = query
        let preservedType = type
        let preservedDestinationID = destinationId
        let preservedDestinationName = destinationName
        let preservedCity = city
        self = ListingSearchCriteria()
        locale = preservedLocale
        query = preservedQuery
        type = preservedType
        destinationId = preservedDestinationID
        destinationName = preservedDestinationName
        city = preservedCity
    }

    func queryItems(locale: String? = nil) -> [URLQueryItem] {
        var values: [(String, String?)] = [
            ("q", query.nilIfBlank),
            ("type", type?.rawValue),
            ("categoryId", categoryId),
            ("destinationId", destinationId),
            ("city", city),
            ("countryCode", countryCode),
            ("minPrice", minPrice.map(Self.decimalString)),
            ("maxPrice", maxPrice.map(Self.decimalString)),
            ("minRating", minRating.map(String.init)),
            ("sort", sort.rawValue),
            ("page", String(page)),
            ("pageSize", String(limit)),
            ("locale", locale ?? self.locale),
        ]

        if !amenityIds.isEmpty {
            values.append(("amenityIds", amenityIds.sorted().joined(separator: ",")))
        }

        if type == .stay {
            values += [
                ("propertyType", propertyType),
                ("checkIn", checkIn.map(Self.apiDate)),
                ("checkOut", checkOut.map(Self.apiDate)),
                ("adults", String(max(1, adults))),
                ("children", String(max(0, children))),
            ]
        } else if type != nil {
            values += [
                ("dateFrom", dateFrom.map(Self.apiDate)),
                ("dateTo", dateTo.map(Self.apiDate)),
                ("participants", String(max(1, participants))),
            ]
        }

        return values.compactMap { name, value in
            value.map { URLQueryItem(name: name, value: $0) }
        }
    }

    nonisolated static func apiDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    nonisolated private static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

typealias ListingQuery = ListingSearchCriteria

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
