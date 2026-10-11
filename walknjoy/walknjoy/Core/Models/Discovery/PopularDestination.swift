import Foundation

struct PopularDestination: Decodable, Identifiable, Hashable {
    let id: String
    let city: String
    let listingCount: Int
    let counts: PopularDestinationCounts
    let coverImage: String?
}
