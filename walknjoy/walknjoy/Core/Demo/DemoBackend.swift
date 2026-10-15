#if DEBUG
    import Foundation
 
    nonisolated final class DemoBackend {
        static let shared = DemoBackend()
        private let lock = NSLock()
        private let sessionKey = "debug.offlineDemoSession"
        private var favorites: Set<String> = []
        private var bookings: [[String: Any]] = []
        private var bookingKeys: [String: [String: Any]] = [:]
        private var firstName = "Demo"
        private var lastName = "İstifadəçi"
        private var preferences: [String: Any] = [
            "bookingUpdates": true, "messages": true, "marketing": false,
        ]
        private let date = "2026-10-12T12:00:00Z"

        var isActive: Bool { UserDefaults.standard.bool(forKey: sessionKey) }
        func begin() {
            lock.withLock {
                favorites = []
                bookings = []
                bookingKeys = [:]
                firstName = "Demo"
                lastName = "İstifadəçi"
                UserDefaults.standard.set(true, forKey: sessionKey)
            }
        }
        func end() { UserDefaults.standard.removeObject(forKey: sessionKey) }

        enum DemoError: LocalizedError {
            case unsupported
            var errorDescription: String? {
                "Bu əməliyyat offline demo rejimində mövcud deyil."
            }
        }

        private var user: [String: Any] {
            [
                "id": "demo-customer", "email": "demo@example.com",
                "firstName": firstName,
                "lastName": lastName, "role": "CUSTOMER", "status": "ACTIVE",
                "createdAt": date, "updatedAt": date, "emailVerifiedAt": date,
            ]
        }
        private func listing(_ type: String) -> [String: Any] {
            let names = [
                "stay": "Şəki demo qonaq evi", "tour": "Bakı İçərişəhər turu",
                "activity": "Qəbələdə təbiət yürüşü",
                "experience": "Azərbaycan mətbəxi təcrübəsi",
            ]
            let details: [String: Any]
            switch type {
            case "stay":
                details = [
                    "propertyType": "guesthouse", "maxGuests": 4,
                    "minimumNights": 1,
                ]
            case "tour":
                details = [
                    "durationMinutes": 90, "maxParticipants": 12,
                    "languages": ["az"],
                ]
            default: details = ["durationMinutes": 90, "maxParticipants": 12]
            }
            return [
                "id": "demo-\(type)", "slug": "demo-\(type)", "type": type,
                "title": names[type] ?? "Demo",
                "shortDescription": "Offline demo nümunəsi",
                "description":
                    "Bu nümunə ilə tətbiqi internet və API olmadan sınaya bilərsiniz.",
                "basePrice": 35, "currency": "AZN", "isFeatured": true,
                "status": "PUBLISHED",
                "location": ["countryCode": "AZ", "city": "Bakı"], "media": [],
                "amenities": [],
                "details": details, "rating": ["average": 4.8, "count": 12],
                "isFavorite": favorites.contains("demo-\(type)"),
            ]
        }
        func response(for endpoint: any Endpoint) throws -> Data {
            try lock.withLock {
                try Task.checkCancellation()
                let path = endpoint.path.trimmingCharacters(
                    in: CharacterSet(charactersIn: "/")
                )
                let query = Dictionary(
                    (endpoint.queryItems ?? []).compactMap { item in
                        item.value.map { (item.name, $0) }
                    },
                    uniquingKeysWith: { _, last in last }
                )
                var input: [String: Any] = [:]
                if case .json(let body) = endpoint.httpBody {
                    input =
                        (try JSONSerialization.jsonObject(
                            with: JSONEncoder().encode(body)
                        )) as? [String: Any] ?? [:]
                }
                let allListings = ["stay", "tour", "activity", "experience"]
                    .map(listing)
                var data: Any
                switch path {
                case "auth/me": data = user
                case "profile":
                    if let value = input["firstName"] as? String {
                        firstName = value
                    }
                    if let value = input["lastName"] as? String {
                        lastName = value
                    }
                    var profile = user
                    profile["phone"] = input["phone"] ?? "+994500000000"
                    profile["stats"] = [
                        "bookings": bookings.count,
                        "favorites": favorites.count, "reviews": 0,
                    ]
                    data = profile
                case "profile/notification-preferences":
                    if !input.isEmpty { preferences = input }
                    data = preferences
                case "profile/avatar" where endpoint.method == .delete:
                    data = ["avatarFile": NSNull()]
                case "listings":
                    data = allListings.filter { value in
                        (query["type"] == nil
                            || value["type"] as? String == query["type"])
                            && (query["q"] == nil
                                || (value["title"] as? String ?? "")
                                    .localizedCaseInsensitiveContains(
                                        query["q"]!
                                    ))
                    }
                case "categories":
                    data = [
                        [
                            "id": "demo-category", "name": "Demo təcrübələr",
                            "slug": "demo", "order": 1,
                            "listingTypes": [
                                "stay", "tour", "activity", "experience",
                            ],
                        ]
                    ]
                case "cities", "amenities", "discovery/popular-destinations",
                    "notifications", "conversations", "profile/reviews":
                    data = [Any]()
                case "notifications/unread-count": data = ["count": 0]
                case "notifications/read-all": data = ["updatedCount": 0]
                case "favorites":
                    data = allListings.filter {
                        favorites.contains($0["id"] as? String ?? "")
                    }
                case _ where path.hasPrefix("favorites/"):
                    let id = String(path.dropFirst("favorites/".count))
                    if endpoint.method == .delete {
                        favorites.remove(id)
                    } else {
                        favorites.insert(id)
                    }
                    data = [
                        "isFavorite": favorites.contains(id),
                        "favoritedAt": date,
                    ]
                case "bookings/availability":
                    data = ["available": true, "price": 35, "currency": "AZN"]
                case "bookings" where endpoint.method == .post:
                    let key =
                        endpoint.headers?["Idempotency-Key"]
                        ?? UUID().uuidString
                    if let existing = bookingKeys[key] {
                        data = existing
                        break
                    }
                    let listingID =
                        input["listingId"] as? String ?? "demo-experience"
                    guard
                        let item = allListings.first(where: {
                            $0["id"] as? String == listingID
                        })
                    else { throw DemoError.unsupported }
                    let adults = input["adults"] as? Int ?? 1
                    let children = input["children"] as? Int ?? 0
                    var booking: [String: Any] = [
                        "id": "demo-booking-\(bookings.count + 1)",
                        "reference": "DEMO-\(bookings.count + 1)",
                        "status": "PENDING", "listing": item,
                        "participants": adults + children, "adults": adults,
                        "children": children,
                        "totalAmount": 35 * (adults + children),
                        "currency": "AZN", "createdAt": date, "updatedAt": date,
                    ]
                    for field in ["checkIn", "checkOut", "customerNote"] {
                        booking[field] = input[field]
                    }
                    bookings.append(booking)
                    bookingKeys[key] = booking
                    data = booking
                case "bookings":
                    data = bookings.filter {
                        query["status"] == nil
                            || $0["status"] as? String == query["status"]
                    }
                case _ where path.hasPrefix("bookings/"):
                    let parts = path.split(separator: "/")
                    guard parts.count >= 2,
                        let index = bookings.firstIndex(where: {
                            $0["id"] as? String == String(parts[1])
                        }), !path.hasSuffix("ticket.pdf")
                    else { throw DemoError.unsupported }
                    if path.hasSuffix("/cancel") {
                        bookings[index]["status"] = "CANCELLED"
                    }
                    data = bookings[index]
                case _
                where path.hasSuffix("/availability")
                    && path.hasPrefix("listings/"):
                    let start = Date().addingTimeInterval(86400)
                    let formatter = ISO8601DateFormatter()
                    data = [
                        "sessions": [
                            [
                                "id": "demo-session",
                                "startsAt": formatter.string(from: start),
                                "endsAt": formatter.string(
                                    from: start.addingTimeInterval(5400)
                                ), "capacity": 12, "remaining": 12,
                            ]
                        ], "blockedPeriods": [],
                    ]
                case _
                where path.hasSuffix("/reviews") && path.hasPrefix("listings/"):
                    data = [Any]()
                case _ where path.hasPrefix("listings/"):
                    let id = String(path.split(separator: "/").last ?? "")
                    guard
                        let value = allListings.first(where: {
                            $0["slug"] as? String == id
                        })
                    else { throw DemoError.unsupported }
                    data = value
                default: throw DemoError.unsupported
                }
                let count = (data as? [Any])?.count ?? 0
                if (Int(query["page"] ?? "1") ?? 1) > 1, data is [Any] {
                    data = [Any]()
                }
                return try JSONSerialization.data(withJSONObject: [
                    "success": true, "data": data,
                    "meta": [
                        "page": Int(query["page"] ?? "1") ?? 1, "limit": 100,
                        "total": count, "totalPages": count == 0 ? 0 : 1,
                    ],
                ])
            }
        }
    }
#endif
