//
//  Favorites.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

nonisolated struct FavoriteRequest: Encodable {
    let listingId: String
}
nonisolated struct FavoriteResponse: Decodable, Equatable {
    let isFavorite: Bool
    let favoritedAt: String?
}

nonisolated struct FavoritesPage {
    let listings: [ListingResponse]
    let meta: PaginationMeta?
}
