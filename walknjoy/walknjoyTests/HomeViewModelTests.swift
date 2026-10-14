import Foundation
import SwiftUI
import Testing

@testable import walknjoy

@MainActor
struct HomeViewModelTests {
    @Test func homeRequestsBypassCachedResponses() throws {
        let model = makeModel(error: nil)
        for type in [ListingType.stay, .tour, .activity, .experience] {
            let request = try ListingEndpoint.getListings(model.makeQuery(for: type)).makeRequest()
            #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
            #expect(request.value(forHTTPHeaderField: "Cache-Control") == "no-cache, no-store")
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
            #expect(items?.contains(URLQueryItem(name: "sort", value: "newest")) == true)
        }
        #expect(try CategoryEndpoint.getCategories.makeRequest().cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(try ListingTaxonomyEndpoint.cities(locale: .az, countryCode: "AZ").makeRequest().cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func descriptionRendersMarkdownHeadingsAndEmphasis() {
        let result = ListingDescriptionFormatter.format("## Ailəsi ilə istirahət\n\n**Rahat** otaqlar")
        #expect(String(result.characters) == "Ailəsi ilə istirahət\n\nRahat otaqlar")
        #expect(result.runs.first?.font != nil)
    }

    @Test func descriptionRendersEditorHTML() {
        let result = ListingDescriptionFormatter.format("<h2>İstirahət</h2><p><strong>Rahat</strong> otaqlar</p>")
        let text = String(result.characters)
        #expect(text.contains("İstirahət"))
        #expect(text.contains("Rahat otaqlar"))
        #expect(!text.contains("<"))
    }

    @Test func cancelledRefreshPreservesVisibleContent() async {
        await expectContentPreserved(after: CancellationError())
    }

    @Test func cancelledURLRequestPreservesVisibleContent() async {
        await expectContentPreserved(after: URLError(.cancelled))
    }

    @Test func failedRefreshPreservesVisibleContent() async {
        await expectContentPreserved(after: NetworkError.noInternet)
    }

    @Test(arguments: ["/categories", "/cities"])
    func taxonomyFailureDoesNotDiscardUpdatedListings(path: String) async {
        let network = HomeRefreshNetwork(error: NetworkError.noInternet, failingPath: path)
        let model = HomeViewModel(
            listingService: ListingServices(networkService: network),
            categoryService: CategoryServices(networkService: network),
            discoveryService: DiscoveryServices(networkService: network)
        )
        model.state = .loaded(content(id: "old-home-listing"))
        await model.refresh()
        guard case .loaded(let updated) = model.state else {
            Issue.record("Taxonomy failure must not discard fresh listings")
            return
        }
        #expect(updated.stays.map(\.id) == ["new-home-listing"])
    }

    @Test func userRefreshFinishesEvenIfSwiftUIActionIsCancelled() async {
        let model = makeModel(error: nil)
        model.state = .loaded(content(id: "old-home-listing"))
        let action = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await model.refreshFromUser()
        }
        await action.value
        guard case .loaded(let updated) = model.state else {
            Issue.record("User refresh must apply its response")
            return
        }
        #expect(updated.stays.map(\.id) == ["new-home-listing"])
    }

    @Test func failedRefreshReportsError() async {
        let model = makeModel(error: NetworkError.noInternet)
        model.state = .loaded(content(id: "old-home-listing"))
        await model.refreshFromUser()
        #expect(model.refreshError != nil)
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
    let failingPath: String?
    init(error: (any Error)?, failingPath: String? = nil) {
        self.error = error
        self.failingPath = failingPath
    }
    func request<T: Decodable>(enpoint: any Endpoint, responseType: T.Type)
        async throws -> T
    {
        if let error, failingPath == nil || failingPath == enpoint.path { throw error }
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
