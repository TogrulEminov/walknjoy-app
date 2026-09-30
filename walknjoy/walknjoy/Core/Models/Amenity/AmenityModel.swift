import Foundation

struct AmenityModel: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let icon: String?
    var isDeleted: Bool
    var listingTypes: [ListingType] = []

    private enum CodingKeys: String, CodingKey { case id, name, description, icon, isDeleted, listingTypes }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        isDeleted = try c.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        listingTypes = try c.decodeIfPresent([ListingType].self, forKey: .listingTypes) ?? []
    }
}
