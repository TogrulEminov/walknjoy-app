//
//  ListingDetails.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//
import Foundation

nonisolated enum ListingDetails: Equatable {
    static func decode(type: ListingType, from decoder: Decoder) throws -> Self
    {
        switch type {
        case .stay: return .stay(try StayDetails(from: decoder))
        case .tour: return .tour(try TourDetails(from: decoder))
        case .activity: return .activity(try ActivityDetails(from: decoder))
        case .experience:
            return .experience(try ExperienceDetails(from: decoder))
        }
    }

    case stay(StayDetails)
    case tour(TourDetails)
    case activity(ActivityDetails)
    case experience(ExperienceDetails)
}

nonisolated struct StayDetails: Codable, Equatable {
    var propertyType: String
    var maxGuests: Int
    var bedrooms: Int? = nil
    var beds: Int? = nil
    var bathrooms: Int? = nil
    var checkInFrom: String? = nil
    var checkInUntil: String? = nil
    var checkOutFrom: String? = nil
    var checkOutUntil: String? = nil
    var minimumNights: Int? = nil
    var instantBooking: Bool? = nil
}
nonisolated struct TourDetails: Codable, Equatable {
    var durationMinutes: Int? = nil
    var maxParticipants: Int? = nil
    var minimumAge: Int? = nil
    var meetingPoint: String? = nil
    var languages: [String]
    var isPrivateTour: Bool? = nil
}
nonisolated struct ActivityDetails: Codable, Equatable {
    var durationMinutes: Int? = nil
    var maxParticipants: Int? = nil
    var minimumAge: Int? = nil
    var difficulty: String? = nil
    var equipmentProvided: Bool? = nil
}

nonisolated struct ExperienceDetails: Codable, Equatable {
    var durationMinutes: Int? = nil
    var maxParticipants: Int? = nil
    var minimumAge: Int? = nil
    var hostIncluded: Bool? = nil
    var isPrivate: Bool? = nil
}
