//
//  ProfileDestination.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

enum ProfileDestination: Hashable {
    case listingDetails(PublicListing)
    // Account
    case editProfile 
    case bookings
    case favorites
    case reviews

    // Settings
    case preferences
    case notifications
    case security

    // Role
    case businessProfile
    case businessDashboard
}
