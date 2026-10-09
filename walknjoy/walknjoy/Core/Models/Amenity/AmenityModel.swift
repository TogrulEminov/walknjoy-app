import Foundation

struct AmenityModel: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let icon: String?
    var isDeleted: Bool?
    var listingTypes: [ListingType] = []

}

extension AmenityModel {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted)
        listingTypes = try container.decodeIfPresent([ListingType].self, forKey: .listingTypes) ?? []
    }
}
