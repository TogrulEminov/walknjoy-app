//
//  PropertyType.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import Foundation

enum PropertyType: String, Decodable, CaseIterable {
    case hotel
    case apartment
    case house
    case villa
    case hostel
    case guestHouse = "guest_house"
    case cottage
    case other

    var title: String {
        switch self {
        case .hotel: String(localized: "listing.propertyType.hotel")
        case .apartment: String(localized: "listing.propertyType.apartment")
        case .house: String(localized: "listing.propertyType.house")
        case .villa: String(localized: "listing.propertyType.villa")
        case .hostel: String(localized: "listing.propertyType.hostel")
        case .guestHouse: String(localized: "listing.propertyType.guest_house")
        case .cottage: String(localized: "listing.propertyType.cottage")
        case .other: String(localized: "listing.propertyType.other")
        }
    }
}
