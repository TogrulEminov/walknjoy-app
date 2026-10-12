//
//  BookingsModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 26.09.26.
//

import Foundation

nonisolated struct BookingRequest: Encodable, Equatable {
    let listingId: String
    let checkIn: String?
    let checkOut: String?
    let sessionId: String?
    let adults: Int
    let children: Int
    let customerNote: String?
}

nonisolated struct AvailabilityRequest: Encodable {
    let listingId: String
    let checkIn: String?
    let checkOut: String?
    let sessionId: String?
    let participants: Int?
}

nonisolated struct BookingSession: Decodable, Identifiable {
    let id: String
    let startsAt: Date
    let endsAt: Date
    let capacity: Int
    let remaining: Int
}

nonisolated struct ListingAvailabilityResponse: Decodable {
    let sessions: [BookingSession]?
    let availableFrom: String?
    let availableUntil: String?
    let blockedPeriods: [BlockedPeriod]?
    struct BlockedPeriod: Decodable {
        let startDate: String
        let endDate: String
    }
}

nonisolated struct AvailabilityResponse: Decodable {
    let available: Bool
    let message: String?
    let reason: String?
    let price: Decimal?
    let currency: String?
}

nonisolated struct BookingResponse: Decodable {
    let id: String
    let reference: String
    let status: String
    let totalAmount: Decimal
    let currency: String

    private enum CodingKeys: String, CodingKey {
        case id
        case reference
        case status
        case totalAmount
        case currency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        reference = try container.decode(String.self, forKey: .reference)
        status = try container.decode(String.self, forKey: .status)
        currency = try container.decode(String.self, forKey: .currency)

        if let amount = try? container.decode(
            Decimal.self,
            forKey: .totalAmount
        ) {
            totalAmount = amount
        } else if let amountString = try? container.decode(
            String.self,
            forKey: .totalAmount
        ),
            let amount = Decimal(
                string: amountString,
                locale: Locale(identifier: "en_US_POSIX")
            )
        {
            totalAmount = amount
        } else {
            throw DecodingError.typeMismatch(
                Decimal.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.totalAmount],
                    debugDescription:
                        "Expected totalAmount to be a number or a numeric string."
                )
            )
        }
    }
}

nonisolated struct BookingsModel: Decodable, Identifiable {
    struct SessionSummary: Decodable {
        let id: String
        let startsAt: String?
        let endsAt: String?

        private enum CodingKeys: String, CodingKey {
            case id, startsAt, endsAt
        }

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer()
            if let sessionId = try? value.decode(String.self) {
                id = sessionId
                startsAt = nil
                endsAt = nil
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            startsAt = try container.decodeIfPresent(
                String.self,
                forKey: .startsAt
            )
            endsAt = try container.decodeIfPresent(String.self, forKey: .endsAt)
        }
    }
 
    struct ListingSummary: Decodable {
        let id: String
        let title: String
        let slug: String?
        let type: ListingType?
        let coverImageUrl: String?
        let isFavorite: Bool

        private enum CodingKeys: String, CodingKey {
            case id, title, slug, type, coverImageUrl, isFavorite
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title =
                try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            slug = try container.decodeIfPresent(String.self, forKey: .slug)
            type = try container.decodeIfPresent(
                ListingType.self,
                forKey: .type
            )
            coverImageUrl = try container.decodeIfPresent(
                String.self,
                forKey: .coverImageUrl
            )
            isFavorite =
                try container.decodeIfPresent(Bool.self, forKey: .isFavorite)
                ?? false
        }
    }

    let id: String
    let reference: String
    let status: String
    let listing: ListingSummary
    let session: SessionSummary?
    let checkIn: String?
    let checkOut: String?
    let participants: Int
    let adults: Int?
    let children: Int?
    let totalAmount: Decimal
    let currency: String
    let customerNote: String?
    let confirmedAt: String?
    let cancelledAt: String?
    let completedAt: String?
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case reference
        case status
        case listing
        case session
        case checkIn
        case checkOut
        case participants
        case adults, children
        case totalAmount
        case currency
        case customerNote
        case confirmedAt
        case cancelledAt
        case completedAt
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        reference = try container.decode(String.self, forKey: .reference)
        status = try container.decode(String.self, forKey: .status)
        listing = try container.decode(ListingSummary.self, forKey: .listing)
        session = try container.decodeIfPresent(
            SessionSummary.self,
            forKey: .session
        )
        checkIn = try container.decodeIfPresent(String.self, forKey: .checkIn)
        checkOut = try container.decodeIfPresent(String.self, forKey: .checkOut)
        participants = try container.decode(Int.self, forKey: .participants)
        adults = try container.decodeIfPresent(Int.self, forKey: .adults)
        children = try container.decodeIfPresent(Int.self, forKey: .children)
        currency = try container.decode(String.self, forKey: .currency)
        customerNote = try container.decodeIfPresent(
            String.self,
            forKey: .customerNote
        )
        confirmedAt = try container.decodeIfPresent(
            String.self,
            forKey: .confirmedAt
        )
        cancelledAt = try container.decodeIfPresent(
            String.self,
            forKey: .cancelledAt
        )
        completedAt = try container.decodeIfPresent(
            String.self,
            forKey: .completedAt
        )
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)

        if let amount = try? container.decode(
            Decimal.self,
            forKey: .totalAmount
        ) {
            totalAmount = amount
        } else if let amountString = try? container.decode(
            String.self,
            forKey: .totalAmount
        ),
            let amount = Decimal(
                string: amountString,
                locale: Locale(identifier: "en_US_POSIX")
            )
        {
            totalAmount = amount
        } else {
            throw DecodingError.typeMismatch(
                Decimal.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.totalAmount],
                    debugDescription:
                        "Expected totalAmount to be a number or a numeric string."
                )
            )
        }
    }
}

nonisolated enum BookingStatus: String, CaseIterable, Identifiable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"
    case completed = "COMPLETED"
    case expired = "EXPIRED"
    var id: String { rawValue }
    var title: String {
        String(
            localized: String.LocalizationValue("booking.status." + rawValue)
        )
    }
    var icon: String {
        switch self {
        case .pending: "clock"
        case .confirmed: "checkmark.circle"
        case .cancelled: "xmark.circle"
        case .completed: "checkmark.seal"
        case .expired: "hourglass"
        }
    }
}

nonisolated extension BookingsModel {
    var statusTitle: String {
        BookingStatus(rawValue: status.uppercased())?.title ?? status
    }
    var statusIcon: String {
        BookingStatus(rawValue: status.uppercased())?.icon ?? "ticket"
    }
    var canCancel: Bool {
        ["PENDING", "CONFIRMED"].contains(status.uppercased())
    }
    var schedule: String {
        if let startsAt = session?.startsAt {
            return Self.timestamp(startsAt) + " – "
                + Self.timestamp(session?.endsAt ?? "")
        }
        return [checkIn, checkOut].compactMap { $0 }.joined(separator: " – ")
    }
    static func timestamp(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        var date = formatter.date(from: value)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: value)
        }
        return date?.formatted(date: .abbreviated, time: .shortened) ?? value
    }
}

nonisolated extension Foundation.Notification.Name {
    static let bookingsChanged = Foundation.Notification.Name(
        "walknjoy.bookingsChanged"
    )
}
