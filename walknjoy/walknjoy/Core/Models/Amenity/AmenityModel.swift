import Foundation

struct AmenityModel: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let icon: String?
    var isDeleted: Bool
    var listingTypes: [ListingType] = []

}
