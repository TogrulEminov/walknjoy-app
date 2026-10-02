import Foundation

struct CategoryModel: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let imageFile: UploadedFile?
    let isDeleted: Bool 
    var listingTypes: [ListingType] { decodedListingTypes ?? [] }
    var order: Int { decodedOrder ?? 0 }

   private let decodedListingTypes: [ListingType]?
    private let decodedOrder: Int?
  private enum CodingKeys: String, CodingKey {
        case id, name, description, imageFile, slug, isDeleted
        case decodedListingTypes = "listingTypes"
        case decodedOrder = "order"
    }
}
