//
//  ListingModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

struct ListingResponse: Decodable, Identifiable {
    let id: String
    let title: String
    let slug: String
    let shortDescription: String?
    let description: String
    let basePrice: String
    let currency: String
    let isFeatured: Bool
    let category: String?
    let location: String?
    let media: UploadedFile
    let amenities: [AmenityModel]
    let rating: Rating
    let isFavorite: Bool
    let type: ListingType
    let details: String?

}
struct Rating: Decodable {
    let average: String?
    let count: Int
}
