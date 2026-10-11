import Foundation

struct PlannerSession: Decodable {
    let sessionId: String
    let version: Int
    let status: String
    let currentStep: String
    let answers: PlannerAnswers
    let message: String
    let input: PlannerInput
    let canGoBack: Bool
    let summary: PlannerSummary?
    let results: PlannerResults?
    let notice: String?
}
struct PlannerAnswers: Decodable {
    let destination: Destination?
    let dates: Dates?
    let guests: Guests?
    let budget: Budget?
    let interests: Interests?
    struct Destination: Decodable { let cityId: String? }
    struct Dates: Decodable { let checkIn: String; let checkOut: String }
    struct Guests: Decodable { let adults: Int; let children: Int }
    struct Budget: Decodable { let amount: String; let currency: String }
    struct Interests: Decodable { let categoryIds: [String] }
}
struct PlannerSummary: Decodable { let destination: String?; let interests: [String]? }
struct PlannerInput: Decodable {
    let type: String
    let options: [Option]?
    let constraints: Constraints?
    struct Option: Decodable, Identifiable {
        let value: String?
        let label: String
        var id: String { value ?? "__any__" }
    }
    struct Constraints: Decodable {
        let nullable: Bool?
        let maxTotal: Int?
        let maxNights: Int?
        let maxSelections: Int?
    }
}
struct PlannerResults: Decodable {
    let items: [PlannerItem]
    let alternatives: [PlannerItem]
    let meta: Meta
    let suggestedChanges: [JSONValue]?
    struct Meta: Decodable { let page: Int; let hasNextPage: Bool }
}
struct PlannerItem: Decodable, Identifiable {
    let listingId: String
    let type: String
    let title: String
    let slug: String
    let image: String?
    let location: Location?
    let dates: PlannerAnswers.Dates?
    let session: Session?
    let breakdown: Breakdown
    let total: String
    let currency: String
    let budgetExceeded: Bool
    let budgetDifference: String
    var id: String { listingId }
    struct Location: Decodable { let city: String? }
    struct Session: Decodable { let id: String; let startsAt: String; let endsAt: String }
    struct Breakdown: Decodable { let basePrice: String; let quantity: Int; let unit: String }
}
// Explicit answer cases prevent accidental fields and preserve cityId:null.
enum PlannerAnswer: Encodable {
    case destination(String?), dates(String, String), guests(Int, Int), budget(String), interests([String]), review
    private enum Keys: String, CodingKey { case cityId, checkIn, checkOut, adults, children, amount, currency, categoryIds, confirmed }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case .destination(let id): if let id { try c.encode(id, forKey: .cityId) } else { try c.encodeNil(forKey: .cityId) }
        case .dates(let start, let end): try c.encode(start, forKey: .checkIn); try c.encode(end, forKey: .checkOut)
        case .guests(let adults, let children): try c.encode(adults, forKey: .adults); try c.encode(children, forKey: .children)
        case .budget(let amount): try c.encode(amount, forKey: .amount); try c.encode("AZN", forKey: .currency)
        case .interests(let ids): try c.encode(ids, forKey: .categoryIds)
        case .review: try c.encode(true, forKey: .confirmed)
        }
    }
}
enum PlannerValues {
    static var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    static func formatter() -> DateFormatter {
        let f = DateFormatter(); f.calendar = calendar; f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }
    static func date(_ string: String) -> Date? { formatter().date(from: string) }
    static func string(_ date: Date) -> String { formatter().string(from: date) }
    static func amount(_ input: String) -> String? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard text.range(of: #"^\d+(\.\d{1,2})?$"#, options: .regularExpression) != nil,
              let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
              value > 0, value <= Decimal(string: "99999999.99")! else { return nil }
        let parts = NSDecimalNumber(decimal: value).stringValue.split(separator: ".")
        return String(parts[0]) + "." + (parts.count > 1 ? String(parts[1]).padding(toLength: 2, withPad: "0", startingAt: 0) : "00")
    }
}
