import Foundation

struct ListingDetailsRoute: Hashable {
    let listing: PublicListing

    static func == (lhs: ListingDetailsRoute, rhs: ListingDetailsRoute) -> Bool {
        lhs.listing.id == rhs.listing.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(listing.id)
    }
}
