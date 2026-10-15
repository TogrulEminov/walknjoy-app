import Foundation
import Testing

@testable import walknjoy

@MainActor
struct StayCalendarTests {
    private func date(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)!
    }

    private func model() async -> BookingViewModel {
        let model = BookingViewModel(
            listingID: "stay",
            slug: "stay",
            type: .stay,
            locale: "az",
            service: BookingService(network: StayCalendarNetwork())
        )
        await model.loadSessions()
        return model
    }

    @Test func blockedNightsAndAvailabilityBoundsCannotBeSelected() async {
        let model = await model()
        #expect(!model.canSelectCheckIn(date("2099-10-19")))
        #expect(model.canSelectCheckIn(date("2099-10-28")))
        #expect(!model.canSelectCheckIn(date("2099-10-29")))
        #expect(!model.canSelectCheckIn(date("2099-11-01")))
        #expect(model.canSelectCheckIn(date("2099-11-02")))
        #expect(!model.canSelectCheckIn(date("2099-11-20")))
    }

    @Test func checkoutCanTouchBlockedStartButCannotCrossBlockedNights() async {
        let model = await model()
        model.selectCheckIn(date("2099-10-28"))
        #expect(model.canSelectCheckOut(date("2099-10-29")))
        #expect(!model.canSelectCheckOut(date("2099-10-30")))
        #expect(!model.canSelectCheckOut(date("2099-11-02")))
        #expect(!model.canSelectCheckOut(date("2099-10-28")))
        #expect(model.canBook)
        model.checkOut = date("2099-11-03")
        #expect(!model.canBook)
    }

    @Test func changingCheckInRepairsInvalidCheckoutAndRejectsBlockedArrival()
        async
    {
        let model = await model()
        model.selectCheckIn(date("2099-11-02"))
        #expect(model.checkOut == date("2099-11-03"))
        #expect(model.canBook)
        model.selectCheckIn(date("2099-10-30"))
        #expect(model.checkIn == date("2099-11-02"))
    }
}

private nonisolated final class StayCalendarNetwork: NetworkingService {
    func request<T: Decodable>(enpoint: any Endpoint, responseType: T.Type)
        async throws -> T
    {
        let json =
            #"{"success":true,"data":{"availableFrom":"2099-10-20","availableUntil":"2099-11-20","blockedPeriods":[{"startDate":"2099-10-29","endDate":"2099-11-02"}]}}"#
        return try JSONDecoder.apiDecoder.decode(
            responseType,
            from: Data(json.utf8)
        )
    }
    func requestData(enpoint: any Endpoint) async throws -> Data {
        throw NetworkError.invalidResponse
    }
}
