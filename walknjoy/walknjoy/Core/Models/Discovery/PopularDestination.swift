import Foundation

struct PopularDestination: Decodable, Identifiable, Hashable {
    struct Counts: Decodable, Hashable {
        let stay: Int
        let tour: Int
        let activity: Int
        let experience: Int
    }

    let id: String
    let city: String
    let listingCount: Int
    let counts: Counts
    let coverImage: String?
}
