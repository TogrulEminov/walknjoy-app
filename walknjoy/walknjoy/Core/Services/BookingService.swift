import Foundation

nonisolated protocol BookingServiceProtocol {
    func getListingAvailability(slug: String, locale: String) async throws
        -> ListingAvailabilityResponse
    func customerPage(page: Int, limit: Int, status: String?) async throws
        -> PaginationPage<BookingsModel>
    func cancelCustomerBooking(id: String) async throws -> BookingsModel
    func getSessions(slug: String, locale: String) async throws
        -> [BookingSession]
    func checkAvailability(request: AvailabilityRequest) async throws
        -> AvailabilityResponse
    func createBooking(request: BookingRequest, idempotencyKey: String)
        async throws -> BookingsModel
    func getBooking(id: String) async throws -> BookingsModel
    func getCustomerBookings() async throws -> [BookingsModel]
    func getBookingTicket(id: String) async throws -> Data

    // Provider methods
    func providerPage(page: Int, limit: Int, status: String?) async throws
        -> PaginationPage<BookingsModel>
    func getProviderBookings() async throws -> [BookingsModel]
    func getProviderBooking(id: String) async throws -> BookingsModel
    func confirmBooking(id: String) async throws -> BookingsModel
    func cancelBooking(id: String) async throws -> BookingsModel
    func completeBooking(id: String) async throws -> BookingsModel

    // Admin methods
    func getAdminBookings() async throws -> [BookingsModel]
    func getAdminBooking(id: String) async throws -> BookingsModel
}

nonisolated final class BookingService: BookingServiceProtocol {
    private let network: NetworkingService

    init(network: NetworkingService) {
        self.network = network
    }

    private func request<T: Decodable>(
        enpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T {
        guard enpoint.path.hasPrefix("/provider/bookings") else {
            return try await network.request(
                enpoint: enpoint,
                responseType: responseType
            )
        }
        let tokens = TokenStorage()
        let token = tokens.accessToken
        do {
            return try await network.request(
                enpoint: enpoint,
                responseType: responseType
            )
        } catch NetworkError.unauthorized {
            if tokens.accessToken == token {
                try await SessionAuthentication.refresh()
            }
            do {
                return try await network.request(
                    enpoint: enpoint,
                    responseType: responseType
                )
            } catch NetworkError.unauthorized {
                await SessionAuthentication.expire()
                throw NetworkError.unauthorized
            }
        }
    }

    private func value<T: Decodable>(_ endpoint: any Endpoint, as type: T.Type)
        async throws -> T
    {
        let response = try await request(
            enpoint: endpoint,
            responseType: ApiResponse<T>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func getSessions(slug: String, locale: String) async throws
        -> [BookingSession]
    {
        try await value(
            BookingEndpoint.listingAvailability(slug: slug, locale: locale),
            as: ListingAvailabilityResponse.self
        ).sessions ?? []
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
        return try await value(
            BookingEndpoint.createBooking(
                request,
                idempotencyKey: idempotencyKey
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

    func getListingAvailability(slug: String, locale: String) async throws
        -> ListingAvailabilityResponse
    {
        try await value(
            BookingEndpoint.listingAvailability(slug: slug, locale: locale),
            as: ListingAvailabilityResponse.self
        )
    }

    func customerPage(page: Int, limit: Int, status: String?) async throws
        -> PaginationPage<BookingsModel>
    {
        let response = try await request(
            enpoint: BookingEndpoint.customerPage(
                page: page,
                limit: limit,
                status: status
            ),
            responseType: ApiResponse<[BookingsModel]>.self
        )
        guard response.success, let data = response.data,
            let meta = response.meta
        else { throw NetworkError.invalidResponse }
        return PaginationPage(items: data, meta: meta)
    }

    func getCustomerBookings() async throws -> [BookingsModel] {
        var items: [BookingsModel] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let result = try await customerPage(
                page: page,
                limit: 100,
                status: nil
            )
            items.append(contentsOf: result.items)
            if !result.hasNextPage(currentPage: page, limit: 100)
                || result.items.isEmpty
            {
                return items
            }
            page += 1
        }
    }

    func cancelCustomerBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.customerCancel(id: id),
            as: BookingsModel.self
        )
    }

    func getBookingTicket(id: String) async throws -> Data {
        try await network.requestData(
            enpoint: BookingEndpoint.getBookingTicket(id: id)
        )
    }

    // MARK: - Provider Methods

    func providerPage(page: Int, limit: Int, status: String?) async throws
        -> PaginationPage<BookingsModel>
    {
        let response = try await request(
            enpoint: BookingEndpoint.providerPage(
                page: page,
                limit: limit,
                status: status
            ),
            responseType: ApiResponse<[BookingsModel]>.self
        )
        guard response.success, let items = response.data,
            let meta = response.meta
        else {
            throw NetworkError.invalidResponse
        }
        return PaginationPage(items: items, meta: meta)
    }

    func getProviderBookings() async throws -> [BookingsModel] {
        var bookings: [BookingsModel] = []
        var page = 1
        while true {
            let result = try await providerPage(
                page: page,
                limit: 100,
                status: nil
            )
            bookings.append(contentsOf: result.items)
            if !result.hasNextPage(currentPage: page, limit: 100)
                || result.items.isEmpty
            {
                return bookings
            }
            page += 1
        }
    }

    func getProviderBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.providerGetBooking(id: id),
            as: BookingsModel.self
        )
    }

    func confirmBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.providerConfirmBooking(id: id),
            as: BookingsModel.self
        )
    }

    func cancelBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.providerCancelBooking(id: id),
            as: BookingsModel.self
        )
    }

    func completeBooking(id: String) async throws -> BookingsModel {
        try await value(
            BookingEndpoint.providerCompleteBooking(id: id),
            as: BookingsModel.self
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
