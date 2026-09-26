//
//  Favorites.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

struct FavoriteRequest: Encodable {
    let listingId: String
}
struct FavoriteResponse: Decodable, Equatable {
    let isFavorite: Bool
    let favoritedAt: String?
}

struct FavoritesPage {
    let listings: [ListingResponse]
    let meta: PaginationMeta?
}
