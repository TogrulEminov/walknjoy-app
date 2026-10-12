import Foundation

nonisolated struct CategoryModel: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let imageFile: UploadedFile?
    let isDeleted: Bool?
    var listingTypes: [ListingType] { decodedListingTypes ?? [] }
    var order: Int { decodedOrder ?? 0 }

    private let decodedListingTypes: [ListingType]?
    private let decodedOrder: Int?

    init(
        id: String,
        name: String,
        slug: String,
        description: String? = nil,
        imageFile: UploadedFile? = nil,
        isDeleted: Bool? = false,
        listingTypes: [ListingType] = [],
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.description = description
        self.imageFile = imageFile
        self.isDeleted = isDeleted
        self.decodedListingTypes = listingTypes
        self.decodedOrder = order
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, imageFile, slug, isDeleted
        case decodedListingTypes = "listingTypes"
        case decodedOrder = "order"
    }
}
