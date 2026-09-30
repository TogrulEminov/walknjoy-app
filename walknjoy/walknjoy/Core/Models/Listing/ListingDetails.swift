//
//  ListingDetails.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//
import Foundation

enum ListingDetails: Codable, Equatable {
    private enum CodingKeys: String, CodingKey { case type, details }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self = try Self.decode(type: c.decode(ListingType.self, forKey: .type), from: c.superDecoder(forKey: .details))
    }

    static func decode(type: ListingType, from decoder: Decoder) throws -> Self {
        switch type {
        case .stay: return .stay(try StayDetails(from: decoder))
        case .tour: return .tour(try TourDetails(from: decoder))
        case .activity: return .activity(try ActivityDetails(from: decoder))
        case .experience: return .experience(try ExperienceDetails(from: decoder))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try encodeBody(to: c.superEncoder(forKey: .details))
    }

    var type: ListingType {
        switch self {
        case .stay: .stay
        case .tour: .tour
        case .activity: .activity
        case .experience: .experience
        }
    }

    func encodeBody(to encoder: Encoder) throws {
        switch self {
        case .stay(let value): try value.encode(to: encoder)
        case .tour(let value): try value.encode(to: encoder)
        case .activity(let value): try value.encode(to: encoder)
        case .experience(let value): try value.encode(to: encoder)
        }
    }

    case stay(StayDetails)
    case tour(TourDetails)
    case activity(ActivityDetails)
    case experience(ExperienceDetails)
}

struct StayDetails: Codable, Equatable {
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
struct TourDetails: Codable, Equatable {
    var durationMinutes: Int? = nil
    var maxParticipants: Int? = nil
    var minimumAge: Int? = nil
    var meetingPoint: String? = nil
    var languages: [String]
    var isPrivateTour: Bool? = nil
}
struct ActivityDetails: Codable, Equatable {
    var durationMinutes: Int? = nil
    var maxParticipants: Int? = nil
    var minimumAge: Int? = nil
    var difficulty: String? = nil
    var equipmentProvided: Bool? = nil
}

struct ExperienceDetails: Codable, Equatable {
    var durationMinutes: Int? = nil
    var maxParticipants: Int? = nil
    var minimumAge: Int? = nil
    var hostIncluded: Bool? = nil
    var isPrivate: Bool? = nil
}
