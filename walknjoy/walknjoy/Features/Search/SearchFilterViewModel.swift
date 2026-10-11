import Foundation
import Observation

@MainActor @Observable
final class SearchFilterViewModel {
    var draft: ListingSearchCriteria
    var minPrice: String
    var maxPrice: String

    init(criteria: ListingSearchCriteria) {
        draft = criteria
        minPrice = criteria.minPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        maxPrice = criteria.maxPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
    }

    var validationErrorKey: String? {
        if let min = decimal(minPrice), let max = decimal(maxPrice), min > max { return "search.validation.price" }
        if let start = draft.checkIn, let end = draft.checkOut, start >= end { return "search.validation.stayDates" }
        if let start = draft.dateFrom, let end = draft.dateTo, start >= end { return "search.validation.dates" }
        return nil
    }

    func criteriaForSubmission() -> ListingSearchCriteria {
        var result = draft
        result.minPrice = decimal(minPrice)
        result.maxPrice = decimal(maxPrice)
        result.page = 1
        return result
    }

    func reset() { draft.resetFilters(); minPrice = ""; maxPrice = "" }
    func setAmenity(_ id: String, selected: Bool) {
        if selected { draft.amenityIds.insert(id) } else { draft.amenityIds.remove(id) }
    }
    private func decimal(_ text: String) -> Decimal? {
        Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX"))
    }
}
