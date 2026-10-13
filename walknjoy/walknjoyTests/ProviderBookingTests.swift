import Foundation
import Testing

@testable import walknjoy

@MainActor
struct ProviderBookingTests {
    @Test
    func pendingCustomerDecodesWithoutContactAndHidesContactEvenIfPresent()
        throws
    {
        let pending = try fixture(status: "PENDING", contact: false)
        #expect(pending.customer?.email == nil)
        #expect(pending.customer?.phone == nil)
        #expect(!pending.canShowCustomerContact)
        #expect(
            !(try fixture(status: "PENDING", contact: true))
                .canShowCustomerContact
        )
        #expect(pending.providerActions() == [.confirm, .cancel])
    }

    @Test func directlyConfirmedBookingHasNoConfirmAction() throws {
        let booking = try fixture(
            status: "CONFIRMED",
            end: "2099-01-01T10:00:00Z",
            contact: true
        )
        #expect(booking.canShowCustomerContact)
        #expect(booking.providerActions() == [.cancel])
    }

    @Test func terminalStatusesHaveNoActions() throws {
        for status in ["COMPLETED", "CANCELLED", "EXPIRED"] {
            #expect(try fixture(status: status).providerActions().isEmpty)
        }
    }

    @Test func stayCompletionUsesCheckOutDateAndRequiresConfirmedStatus() throws
    {
        let now = Date(timeIntervalSince1970: 1_791_849_600)  // 2026-10-13 UTC
        let past = try fixture(
            status: "CONFIRMED",
            type: "stay",
            end: "2026-10-12"
        )
        let future = try fixture(
            status: "CONFIRMED",
            type: "stay",
            end: "2099-01-01"
        )
        #expect(past.canProviderComplete(now: now))
        #expect(!future.canProviderComplete(now: now))
        #expect(
            !(try fixture(status: "PENDING", type: "stay", end: "2026-10-12"))
                .canProviderComplete(now: now)
        )
    }

    @Test func sessionCompletionRequiresPastEndTime() throws {
        let now = Date(timeIntervalSince1970: 1_791_849_600)
        #expect(
            try fixture(status: "CONFIRMED", end: "2026-10-01T10:00:00Z")
                .canProviderComplete(now: now)
        )
        #expect(
            !(try fixture(status: "CONFIRMED", end: "2099-01-01T10:00:00Z"))
                .canProviderComplete(now: now)
        )
    }

    @Test func providerEndpointsSendBearerRequiredRequestsWithoutActionBody()
        throws
    {
        for endpoint in [
            BookingEndpoint.providerConfirmBooking(id: "booking-1"),
            .providerCancelBooking(id: "booking-1"),
            .providerCompleteBooking(id: "booking-1"),
        ] {
            let request = try endpoint.makeRequest()
            #expect(request.httpMethod == "POST")
            #expect(request.httpBody == nil)
            #expect(endpoint.requiresAuth)
            #expect(
                request.url?.path.hasPrefix(
                    "/api/v1/provider/bookings/booking-1/"
                ) == true
            )
        }
        let all = BookingEndpoint.providerPage(page: 1, limit: 20, status: nil)
        #expect(
            all.queryItems?.contains(where: { $0.name == "status" }) == false
        )
        #expect(
            BookingEndpoint.providerPage(page: 2, limit: 20, status: "PENDING")
                .queryItems?.first(where: { $0.name == "status" })?.value
                == "PENDING"
        )
    }

    @Test func providerListPassesFilterAndAppendsNextPage() async {
        let network = ProviderBookingFixtureNetwork()
        let model = BookingListViewModel(
            role: .provider,
            service: BookingService(network: network)
        )
        model.status = "PENDING"
        await model.loadBookings()
        #expect(model.bookings.map(\.id) == ["booking-1"])
        await model.loadMore()
        #expect(model.bookings.map(\.id) == ["booking-1", "booking-2"])
        #expect(network.pages == ["1", "2"])
        #expect(network.filters == ["PENDING", "PENDING"])
        #expect(!model.pagination.hasMore)
    }

    @Test func confirmSuccessRemovesCardFromPendingFilter() async throws {
        let network = ProviderBookingFixtureNetwork()
        let model = BookingListViewModel(
            role: .provider,
            service: BookingService(network: network)
        )
        model.status = "PENDING"
        await model.loadBookings()
        let booking = try #require(model.bookings.first)
        await model.performProviderAction(.confirm, booking: booking)
        #expect(model.bookings.isEmpty)
        #expect(model.pagination.items.isEmpty)
        #expect(model.providerActions.error == nil)
        #expect(network.actionCount == 1)
    }

    @Test func conflictReloadsCurrentBookingAndShowsMessage() async throws {
        let network = ProviderBookingFixtureNetwork()
        network.actionFailure = APIRequestFailure(
            error: ApiError(
                code: "BOOKING_STATUS_CONFLICT",
                message: "Status changed",
                details: nil
            ),
            statusCode: 409
        )
        let model = ProviderBookingActionsModel(
            service: BookingService(network: network)
        )
        let result = await model.perform(
            .confirm,
            booking: try fixture(status: "PENDING")
        )
        #expect(result == nil)
        #expect(model.refreshedBooking?.status == "CONFIRMED")
        #expect(model.error?.contains("Status changed") == true)
        #expect(model.busyID == nil)
        #expect(network.detailCount == 1)
    }

    @Test func duplicateActionIsBlockedWhileRequestIsInFlight() async throws {
        let network = ProviderBookingFixtureNetwork()
        let gate = ProviderBookingGate()
        network.gate = gate
        let model = ProviderBookingActionsModel(
            service: BookingService(network: network)
        )
        let booking = try fixture(status: "PENDING")
        let first = Task { await model.perform(.confirm, booking: booking) }
        await gate.waitUntilStarted()
        #expect(model.busyID == booking.id)
        let second = await model.perform(.confirm, booking: booking)
        #expect(second == nil)
        #expect(network.actionCount == 1)
        await gate.release()
        _ = await first.value
        #expect(model.busyID == nil)
    }

    @Test func forbiddenAndNotFoundAreHandledWithoutChangingToSuccess()
        async throws
    {
        for status in [403, 404] {
            let network = ProviderBookingFixtureNetwork()
            network.actionFailure = APIRequestFailure(
                error: ApiError(
                    code: "DENIED",
                    message: "Denied",
                    details: nil
                ),
                statusCode: status
            )
            let model = ProviderBookingActionsModel(
                service: BookingService(network: network)
            )
            let result = await model.perform(
                .confirm,
                booking: try fixture(status: "PENDING")
            )
            #expect(result == nil)
            #expect(model.error != nil)
            #expect(model.unavailableID == (status == 404 ? "booking-1" : nil))
        }
    }

    @Test func detailActionAppliesFullResponseIncludingContact() async throws {
        let network = ProviderBookingFixtureNetwork()
        let model = BookingDetailViewModel(
            bookingID: "booking-1",
            role: .provider,
            service: BookingService(network: network)
        )
        model.booking = try fixture(status: "PENDING")
        await model.performProviderAction(.confirm)
        #expect(model.booking?.status == "CONFIRMED")
        #expect(model.booking?.customer?.email == "guest@example.com")
        #expect(model.booking?.canShowCustomerContact == true)
    }

    @Test func cancelAndCompleteApplyExpectedStatuses() async throws {
        for action in [ProviderBookingAction.cancel, .complete] {
            let model = ProviderBookingActionsModel(
                service: BookingService(
                    network: ProviderBookingFixtureNetwork()
                )
            )
            let result = await model.perform(
                action,
                booking: try fixture(status: "CONFIRMED")
            )
            #expect(result?.status == action.expectedStatus)
            #expect(model.error == nil)
        }
    }

    private func fixture(
        status: String,
        type: String = "tour",
        end: String = "2026-10-01T10:00:00Z",
        contact: Bool = false
    ) throws -> BookingsModel {
        try JSONDecoder.apiDecoder.decode(
            BookingsModel.self,
            from: Data(
                ProviderBookingFixtureNetwork.json(
                    status: status,
                    type: type,
                    end: end,
                    contact: contact
                ).utf8
            )
        )
    }
}

private nonisolated final class ProviderBookingFixtureNetwork: NetworkingService
{
    var pages: [String] = []
    var filters: [String?] = []
    var actionCount = 0
    var detailCount = 0
    var actionFailure: APIRequestFailure?
    var gate: ProviderBookingGate?

    func request<T: Decodable>(enpoint: any Endpoint, responseType: T.Type)
        async throws -> T
    {
        let json: String
        if enpoint.method == .post {
            actionCount += 1
            if let gate { await gate.hold() }
            if let actionFailure { throw actionFailure }
            let status =
                enpoint.path.hasSuffix("/cancel")
                ? "CANCELLED"
                : enpoint.path.hasSuffix("/complete")
                    ? "COMPLETED" : "CONFIRMED"
            json =
                "{\"success\":true,\"data\":\(Self.json(status: status, contact: true))}"
        } else if enpoint.path == "/provider/bookings/" {
            let page =
                enpoint.queryItems?.first(where: { $0.name == "page" })?.value
                ?? "1"
            pages.append(page)
            filters.append(
                enpoint.queryItems?.first(where: { $0.name == "status" })?.value
            )
            json =
                "{\"success\":true,\"data\":[\(Self.json(id: "booking-\(page)", status: "PENDING"))],\"meta\":{\"page\":\(page),\"limit\":20,\"total\":2,\"totalPages\":2}}"
        } else {
            detailCount += 1
            json =
                "{\"success\":true,\"data\":\(Self.json(status: "CONFIRMED", contact: true))}"
        }
        return try JSONDecoder.apiDecoder.decode(
            responseType,
            from: Data(json.utf8)
        )
    }
    func requestData(enpoint: any Endpoint) async throws -> Data {
        throw NetworkError.invalidResponse
    }

    static func json(
        id: String = "booking-1",
        status: String,
        type: String = "tour",
        end: String = "2026-10-01T10:00:00Z",
        contact: Bool = false
    ) -> String {
        let contactFields =
            contact
            ? ",\"email\":\"guest@example.com\",\"phone\":\"+994500000000\""
            : ""
        let session =
            type == "stay"
            ? "null"
            : "{\"id\":\"session-1\",\"startsAt\":\"2026-10-01T08:00:00Z\",\"endsAt\":\"\(end)\"}"
        let checkOut = type == "stay" ? "\"\(end)\"" : "null"
        return """
            {"id":"\(id)","listingId":"listing-1","reference":"WNJ-1","status":"\(status)",
            "listing":{"id":"listing-1","type":"\(type)","title":"Elan","slug":"elan","coverImageUrl":null},
            "customer":{"id":"customer-1","firstName":"Emin","lastName":"Test"\(contactFields)},
            "session":\(session),"checkIn":null,"checkOut":\(checkOut),"participants":2,"adults":2,"children":0,
            "totalAmount":"50","currency":"AZN","customerNote":null,"confirmedAt":null,
            "cancelledAt":null,"completedAt":null,"createdAt":"2026-10-01T00:00:00Z","updatedAt":"2026-10-01T00:00:00Z"}
            """
    }
}

private actor ProviderBookingGate {
    private var started = false
    private var observers: [CheckedContinuation<Void, Never>] = []
    private var request: CheckedContinuation<Void, Never>?
    func hold() async {
        started = true
        observers.forEach { $0.resume() }
        observers = []
        await withCheckedContinuation { request = $0 }
    }
    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { observers.append($0) }
    }
    func release() {
        request?.resume()
        request = nil
    }
}
