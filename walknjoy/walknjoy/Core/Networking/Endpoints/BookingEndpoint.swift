import Foundation

enum BookingEndpoint {
    case listingAvailability(slug: String, locale: String)
    case checkAvailability(AvailabilityRequest)
    case createBooking(BookingRequest)
    case getBooking(id: String)
    case getBookingTicket(id: String)
    case customerListBookings
    case customerPage(page: Int, limit: Int, status: String?)
    case customerCancel(id: String)

    // Provider Endpoints
    case providerListBookings
    case providerGetBooking(id: String)
    case providerConfirmBooking(id: String)
    case providerCancelBooking(id: String)
    case providerCompleteBooking(id: String)

    // Admin Endpoints
    case adminListBookings
    case adminGetBooking(id: String)
}

extension BookingEndpoint: Endpoint {
    var baseURL: String {
        APIConfig.baseURL
    }

    var path: String {
        switch self {
        case .listingAvailability(let slug, _):
            "/listings/\(slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/?#%"))) ?? slug)/availability"
        case .checkAvailability:
            "/bookings/availability"
        case .createBooking:
            "/bookings"
        case .getBooking(let id):
            "/bookings/\(id)"
        case .getBookingTicket(let id):
            "/bookings/\(id)/ticket.pdf"
        case .customerListBookings, .customerPage:
            "/bookings/"
        case .customerCancel(let id):
            "/bookings/\(id)/cancel"
        case .providerListBookings:
            "/provider/bookings/"
        case .providerGetBooking(let id):
            "/provider/bookings/\(id)"
        case .providerConfirmBooking(let id):
            "/provider/bookings/\(id)/confirm"
        case .providerCancelBooking(let id):
            "/provider/bookings/\(id)/cancel"
        case .providerCompleteBooking(let id):
            "/provider/bookings/\(id)/complete"
        case .adminListBookings:
            "/admin/bookings/"
        case .adminGetBooking(let id):
            "/admin/bookings/\(id)"
        }
    }

    var method: HttpMethod {
        switch self {
        case .listingAvailability, .checkAvailability, .getBooking,
            .getBookingTicket,
            .customerListBookings, .customerPage, .providerListBookings,
            .providerGetBooking,
            .adminListBookings, .adminGetBooking:
            .get
        case .createBooking, .customerCancel, .providerConfirmBooking,
            .providerCancelBooking,
            .providerCompleteBooking:
            .post
        }
    }

    var headers: [String: String]? {
        nil
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .listingAvailability(_, let locale):
            return [URLQueryItem(name: "locale", value: locale)]
        case .checkAvailability(let request):
            return [
                URLQueryItem(name: "listingId", value: request.listingId),
                URLQueryItem(name: "checkIn", value: request.checkIn),
                URLQueryItem(name: "checkOut", value: request.checkOut),
                URLQueryItem(name: "sessionId", value: request.sessionId),
                URLQueryItem(
                    name: "participants",
                    value: request.participants.map(String.init)
                ),
            ].filter { $0.value != nil }
        case .customerPage(let page, let limit, let status):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(
                    name: "limit",
                    value: String(min(100, max(1, limit)))
                ), URLQueryItem(name: "status", value: status),
            ].filter { $0.value != nil }
        case .adminListBookings: 
            return nil
        default:
            return nil
        }
    }

    var httpBody: RequestBody {
        switch self {
        case .createBooking(let request):
            .json(request)
        default:
            .none
        }
    }

    var requiresAuth: Bool {
        if case .listingAvailability = self { return false }
        return true
    }

    var usesOptionalAuth: Bool {
        false
    }
}
