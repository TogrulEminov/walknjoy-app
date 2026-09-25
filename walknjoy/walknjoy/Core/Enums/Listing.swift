//
//  Listing.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import Foundation

enum ListingType: String {
    case stay = "STAY"
    case tour = "TOUR"
    case activity = "ACTIVITY"
    case experience = "EXPERIENCE"
}

enum ListingStatus: String {
    case draft = "DRAFT"
    case pendingReview = "PENDING_REVIEW"
    case published = "PUBLISHED"
    case rejected = "REJECTED"
    case archived = "ARCHIVED"
}
