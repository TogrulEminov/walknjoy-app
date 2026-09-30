//
//  BookingsModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 26.09.26.
//

import Foundation

struct BookingsRequest {

}

struct BookingsModel {
    let reference: String
    let status: String
    let listing: ListingResponse
    let session: String?
    let checkIn: String?
    let checkOut: String?
    let participants: Int
    let totalAmount: String
    let currency: String
    let customerNote: String?
    let confirmedAt: String?
    let cancelledAt: String?
    let completedAt: String?
    let createdAt: String
    let updatedAt: String
}
