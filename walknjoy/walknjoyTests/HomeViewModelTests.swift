import Foundation
import Testing

@testable import walknjoy

@MainActor
struct HomeViewModelTests {
    @Test func cancelledRefreshPreservesVisibleContent() async {
        await expectContentPreserved(after: CancellationError())
    }

    @Test func cancelledURLRequestPreservesVisibleContent() async {
        await expectContentPreserved(after: URLError(.cancelled))
    }

    @Test func failedRefreshPreservesVisibleContent() async {
        await expectContentPreserved(after: NetworkError.noInternet)
    }

    @Test func successfulRefreshReplacesContent() async {
        let model = makeModel(error: nil)
        model.state = .loaded(content(id: "old-home-listing"))
        await model.refresh()
        guard case .loaded(let updated) = model.state else {
            Issue.record("Refresh must keep Home loaded")
            return
        }
        #expect(updated.stays.map(\.id) == ["new-home-listing"])
    }

    private func expectContentPreserved(after error: any Error) async {
        let model = makeModel(error: error)
        model.state = .loaded(content(id: "existing-home-listing"))
        await model.refresh()
        guard case .loaded(let existing) = model.state else {
            Issue.record("Refresh must not clear existing Home content")
            return
        }
        #expect(existing.stays.map(\.id) == ["existing-home-listing"])
    }

    private func content(id: String) -> HomeContent {
        HomeContent(
            cities: [],
            categories: [],
            stays: [
                PublicListing(
                    id: id,
                    type: .stay,
                    title: "Elan",
                    slug: id,
                    basePrice: 25,
                    currency: "AZN"
                )
            ],
            tours: [],
            activities: [],
            experiences: []
        )
    }

    private func makeModel(error: (any Error)?) -> HomeViewModel {
        let network = HomeRefreshNetwork(error: error)
        return HomeViewModel(
            listingService: ListingServices(networkService: network),
            categoryService: CategoryServices(networkService: network),
            discoveryService: DiscoveryServices(networkService: network)
        )
    }
}

private nonisolated final class HomeRefreshNetwork: NetworkingService {
    let error: (any Error)?
    init(error: (any Error)?) { self.error = error }
    func request<T: Decodable>(enpoint: any Endpoint, responseType: T.Type)
        async throws -> T
    {
        if let error { throw error }
        let items =
            enpoint.path == "/listings"
            ? #"[{"id":"new-home-listing","type":"stay","title":"Elan","slug":"new-home-listing","basePrice":"25","currency":"AZN"}]"#
            : "[]"
        let json =
            "{\"success\":true,\"data\":\(items),\"meta\":{\"page\":1,\"limit\":6,\"total\":1,\"totalPages\":1}}"
        return try JSONDecoder.apiDecoder.decode(
            responseType,
            from: Data(json.utf8)
        )
    }
    func requestData(enpoint: any Endpoint) async throws -> Data {
        throw NetworkError.invalidResponse
    }
}
