//
//  ListingSort.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import Foundation

enum ListingSort: String, Codable, CaseIterable, Identifiable {
    case newest
    case priceAscending = "price_asc"
    case priceDescending = "price_desc"
    case featured
    case ratingDescending = "rating_desc"

    var id: Self { self }
}
