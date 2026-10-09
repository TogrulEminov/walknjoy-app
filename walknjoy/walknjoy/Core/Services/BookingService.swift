import Foundation

protocol BookingServiceProtocol {
    func getListingAvailability(slug: String, locale: String) async throws -> ListingAvailabilityResponse
    func customerPage(page: Int, limit: Int, status: String?) async throws -> PaginationPage<BookingsModel>
    func cancelCustomerBooking(id: String) async throws -> BookingsModel
    func getSessions(slug: String, locale: String) async throws -> [BookingSession]
    func checkAvailability(request: AvailabilityRequest) async throws
        -> AvailabilityResponse
    func createBooking(request: BookingRequest, idempotencyKey: String)
        async throws -> BookingsModel
    func getBooking(id: String) async throws -> BookingsModel
    func getCustomerBookings() async throws -> [BookingsModel]
    func getBookingTicket(id: String) async throws -> Data

    // Provider methods
    func getProviderBookings() async throws -> [BookingsModel]
    func getProviderBooking(id: String) async throws -> BookingsModel
    func confirmBooking(id: String) async throws -> BookingResponse
    func cancelBooking(id: String) async throws -> BookingResponse
    func completeBooking(id: String) async throws -> BookingResponse

    // Admin methods
    func getAdminBookings() async throws -> [BookingsModel]
    func getAdminBooking(id: String) async throws -> BookingsModel
}

@MainActor
final class BookingService: BookingServiceProtocol {
    private let network: NetworkingService

    init(network: NetworkingService? = nil) {
        self.network = network ?? DefaultNetworkService()
    }

    private func value<T: Decodable>(_ endpoint: any Endpoint, as type: T.Type)
        async throws -> T
    {
        let response = try await network.request(
            enpoint: endpoint,
            responseType: ApiResponse<T>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func getSessions(slug: String, locale: String) async throws -> [BookingSession] {
        try await value(BookingEndpoint.listingAvailability(slug: slug, locale: locale), as: ListingAvailabilityResponse.self).sessions ?? []
    }

    func checkAvailability(request: AvailabilityRequest) async throws
        -> AvailabilityResponse
    {
        try await value(
            BookingEndpoint.checkAvailability(request),
            as: AvailabilityResponse.self
        )
    }

    func createBooking(request: BookingRequest, idempotencyKey: String)
        async throws -> BookingsModel
    {
        struct IdempotentBookingEndpoint: Endpoint {
            let request: BookingRequest
            let key: String
            var baseURL: String { APIConfig.baseURL }
            var path: String { "/bookings" }
            var method: HttpMethod { .post }
            var headers: [String: String]? {
                ["Idempotency-Key": key]
            }
            var queryItems: [URLQueryItem]? { nil }
            var httpBody: RequestBody { .json(request) }
            var requiresAuth: Bool { true }
            var usesOptionalAuth: Bool { false }
        }

        return try await value(
            IdempotentBookingEndpoint(
                request: request,
                key: idempotencyKey
            ),
            as: BookingsModel.self
        )
    }

    func getBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.getBooking(id: id),
            as: BookingsModel.self
        )
    }

    func getListingAvailability(slug: String, locale: String) async throws -> ListingAvailabilityResponse {
        try await value(BookingEndpoint.listingAvailability(slug: slug, locale: locale), as: ListingAvailabilityResponse.self)
    }

    func customerPage(page: Int, limit: Int, status: String?) async throws -> PaginationPage<BookingsModel> {
        let response = try await network.request(enpoint: BookingEndpoint.customerPage(page: page, limit: limit, status: status), responseType: ApiResponse<[BookingsModel]>.self)
        guard response.success, let data = response.data, let meta = response.meta else { throw NetworkError.invalidResponse }
        return PaginationPage(items: data, meta: meta)
    }

    func getCustomerBookings() async throws -> [BookingsModel] {
        var items: [BookingsModel] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let result = try await customerPage(page: page, limit: 100, status: nil)
            items.append(contentsOf: result.items)
            if !result.hasNextPage(currentPage: page, limit: 100) || result.items.isEmpty { return items }
            page += 1
        }
    }

    func cancelCustomerBooking(id: String) async throws -> BookingsModel {
        try await value(BookingEndpoint.customerCancel(id: id), as: BookingsModel.self)
    }

    func getBookingTicket(id: String) async throws -> Data {
        try await network.requestData(
            enpoint: BookingEndpoint.getBookingTicket(id: id)
        )
    }

    // MARK: - Provider Methods

    func getProviderBookings() async throws -> [BookingsModel] {
        try await value(
            BookingEndpoint.providerListBookings,
            as: [BookingsModel].self
        )
    }

    func getProviderBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.providerGetBooking(id: id),
            as: BookingsModel.self
        )
    }

    func confirmBooking(id: String) async throws -> BookingResponse {
        try await value(
            BookingEndpoint.providerConfirmBooking(id: id),
            as: BookingResponse.self
        )
    }

    func cancelBooking(id: String) async throws -> BookingResponse {
        try await value(
            BookingEndpoint.providerCancelBooking(id: id),
            as: BookingResponse.self
        )
    }

    func completeBooking(id: String) async throws -> BookingResponse {
        try await value(
            BookingEndpoint.providerCompleteBooking(id: id),
            as: BookingResponse.self
        )
    }

    // MARK: - Admin Methods

    func getAdminBookings() async throws -> [BookingsModel] {
        try await value(
            BookingEndpoint.adminListBookings,
            as: [BookingsModel].self
        )
    }

    func getAdminBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.adminGetBooking(id: id),
            as: BookingsModel.self
        )
    }
}
