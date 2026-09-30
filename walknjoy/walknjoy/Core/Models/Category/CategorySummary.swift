import Foundation

struct CategoryModel: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let imageFile: UploadedFile?
    let isDeleted: Bool
    private let decodedListingTypes: [ListingType]?
    private let decodedOrder: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, imageFile, slug, isDeleted
        case decodedListingTypes = "listingTypes"
        case decodedOrder = "order"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decode(String.self, forKey: .slug)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        imageFile = try c.decodeIfPresent(UploadedFile.self, forKey: .imageFile)
        isDeleted = try c.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        decodedListingTypes = try c.decodeIfPresent([ListingType].self, forKey: .decodedListingTypes)
        decodedOrder = try c.decodeIfPresent(Int.self, forKey: .decodedOrder)
    }

    var listingTypes: [ListingType] { decodedListingTypes ?? [] }
    var order: Int { decodedOrder ?? 0 }

}
