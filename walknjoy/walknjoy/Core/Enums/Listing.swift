//
//  Listing.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import Foundation
import SwiftUI

enum ListingType: String, Codable, CaseIterable, Hashable, Identifiable,
    Equatable
{
    case stay
    case tour
    case activity
    case experience

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .stay: "listing.type.stay"

        case .tour: "listing.type.tour"
        case .activity: "listing.type.activity"
        case .experience: "listing.type.experience"
        }
    }
    var icon: String {
        switch self {
        case .stay:
            "bed.double.fill"
        case .tour:
            "map.fill"
        case .activity:
            "figure.hiking"

        case .experience:
            "sparkles"
        }
    }
}

enum ListingStatus: String, Codable {
    case draft = "DRAFT"
    case pendingReview = "PENDING_REVIEW"
    case published = "PUBLISHED"
    case rejected = "REJECTED"
    case archived = "ARCHIVED"
}

extension ListingStatus {
    var localizedTitle: String {
        switch self {
        case .draft: String(localized: "listing.status.draft")
        case .pendingReview: String(localized: "listing.status.pendingReview")
        case .published: String(localized: "listing.status.published")
        case .rejected: String(localized: "listing.status.rejected")
        case .archived: String(localized: "listing.status.archived")
        }
    }
}
