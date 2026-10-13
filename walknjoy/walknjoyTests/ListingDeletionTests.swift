import Foundation
import Testing

@testable import walknjoy

@MainActor
struct ListingDeletionTests {
    @Test func missingIsDeletedDefaultsToFalseForCardAndEditor() throws {
        let card = try ListingDeletionFixtures.card(id: "legacy-card")
        let encoded = try JSONEncoder().encode(card)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "isDeleted")
        let decoded = try JSONDecoder.apiDecoder.decode(
            ProviderListingCardDTO.self,
            from: JSONSerialization.data(withJSONObject: object)
        )
        #expect(!decoded.isDeleted)

        let json = ListingDeletionFixtures.editorJSON(
            id: "legacy-editor",
            deleted: false
        )
        .replacingOccurrences(of: "\"isDeleted\":false,", with: "")
        let response = try JSONDecoder.apiDecoder.decode(
            ApiResponse<ProviderListingEditorDTO>.self,
            from: Data(json.utf8)
        )
        #expect(response.data?.isDeleted == false)
    }

    @Test func cardDecodesCanDeleteAndArchivedRemainsAValidStatus() throws {
        let listing = try ListingDeletionFixtures.card(
            id: "card-contract",
            status: "ARCHIVED"
        )
        #expect(listing.actions.canDelete)
        #expect(!listing.isDeleted)
        #expect(listing.status == .archived)
    }

    @Test func deleteDecodesListingResponseAndPreservesPreviousStatus()
        async throws
    {
        let network = ListingDeletionNetwork(
            body: ListingDeletionFixtures.editorJSON(
                id: "delete-contract",
                deleted: true
            )
        )
        let deleted = try await ProviderListingService(network: network).delete(
            id: "delete-contract"
        )
        #expect(deleted.isDeleted)
        #expect(deleted.status == .published)
        #expect(network.endpoint?.path == "/provider/listings/delete-contract")
        #expect(network.endpoint?.method == .delete)
        #expect(network.endpoint?.requiresAuth == true)
    }

    @Test func deleteRejectsResponseThatIsNotDeleted() async {
        let network = ListingDeletionNetwork(
            body: ListingDeletionFixtures.editorJSON(
                id: "invalid-delete",
                deleted: false
            )
        )
        do {
            _ = try await ProviderListingService(network: network).delete(
                id: "invalid-delete"
            )
            Issue.record("Expected isDeleted validation failure")
        } catch {
            #expect(error is NetworkError)
        }
    }

    @Test func failedDeleteKeepsListingAndDisplaysError() async throws {
        let listing = try ListingDeletionFixtures.card(id: "failed-delete")
        let service = ListingDeletionMock(listing: listing)
        service.failDelete = true
        let model = ProviderListingsViewModel(service: service)
        await model.reload()

        await model.delete(listing)

        #expect(model.listings.map(\.id) == [listing.id])
        #expect(model.mutationError != nil)
        #expect(model.mutatingID == nil)
        #expect(!ListingLifecycle.shared.deletedIDs.contains(listing.id))
    }

    @Test func successfulDeleteRemovesCachedListingEvenWhenReloadFails()
        async throws
    {
        let listing = try ListingDeletionFixtures.card(id: "successful-delete")
        let service = ListingDeletionMock(listing: listing)
        let model = ProviderListingsViewModel(service: service)
        await model.reload()
        service.failReload = true

        await model.delete(listing)

        #expect(model.listings.isEmpty)
        #expect(ListingLifecycle.shared.deletedIDs.contains(listing.id))
        #expect(model.mutationError == nil)
        #expect(model.mutatingID == nil)
    }

    @Test func updateSupportsPartialTitleAndExcludesManagedFields() throws {
        let input = UpdateListingRequest(locale: .az, title: "Yeni başlıq")
        let body = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(input))
                as? [String: Any]
        )
        #expect(Set(body.keys) == ["locale", "title"])
        let endpoint = ProviderListingEndpoint.update(
            id: "listing-1",
            input: input
        )
        #expect(endpoint.method == .patch)
    }

    @Test func publicDTOStillDecodesWithoutIsDeletedOrActions() throws {
        let json =
            #"{"id":"public","type":"experience","title":"Elan","slug":"elan","basePrice":"25","currency":"AZN"}"#
        let listing = try JSONDecoder.apiDecoder.decode(
            PublicListing.self,
            from: Data(json.utf8)
        )
        #expect(listing.id == "public")
    }
}

private nonisolated enum ListingDeletionFixtures {
    static func card(id: String, status: String = "PUBLISHED") throws
        -> ProviderListingCardDTO
    {
        let json = """
            {"id":"\(id)","type":"experience","status":"\(status)","isDeleted":false,
            "title":"Elan","slug":"elan","coverMedia":null,"category":null,"location":null,
            "basePrice":"25","currency":"AZN","rating":{"average":null,"count":0},
            "actions":{"canEdit":true,"canSubmit":false,"canDelete":true},"updatedAt":"2026-10-13T10:00:00Z"}
            """
        return try JSONDecoder.apiDecoder.decode(
            ProviderListingCardDTO.self,
            from: Data(json.utf8)
        )
    }
    static func editorJSON(id: String, deleted: Bool) -> String {
        """
        {"success":true,"data":{"id":"\(id)","providerId":"provider-1","categoryId":null,
        "type":"experience","status":"PUBLISHED","isDeleted":\(deleted),"basePrice":"25","currency":"AZN",
        "isFeatured":false,"rejectionReason":null,"translations":[],"location":null,"media":[],
        "createdAt":"2026-10-13T10:00:00Z","updatedAt":"2026-10-13T10:00:00Z"}}
        """
    }
}

private nonisolated final class ListingDeletionNetwork: NetworkingService {
    let body: String
    var endpoint: (any Endpoint)?
    init(body: String) { self.body = body }
    func request<T: Decodable>(enpoint: any Endpoint, responseType: T.Type)
        async throws -> T
    {
        endpoint = enpoint
        return try JSONDecoder.apiDecoder.decode(
            responseType,
            from: Data(body.utf8)
        )
    }
    func requestData(enpoint: any Endpoint) async throws -> Data {
        throw NetworkError.invalidResponse
    }
}

private nonisolated final class ListingDeletionMock: ProviderListingsManaging {
    let listing: ProviderListingCardDTO
    var failDelete = false
    var failReload = false
    init(listing: ProviderListingCardDTO) { self.listing = listing }
    func categories(type: ListingType?, locale: ListingLocale) async throws
        -> [CategoryModel]
    { [] }
    func list(query: ProviderListingsQuery) async throws -> ApiResponse<
        [ProviderListingCardDTO]
    > {
        if failReload { throw NetworkError.noInternet }
        return ApiResponse(
            success: true,
            data: [listing],
            meta: PaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1)
        )
    }
    func delete(id: String) async throws -> ProviderListingEditorDTO {
        if failDelete { throw NetworkError.noInternet }
        let response = try JSONDecoder.apiDecoder.decode(
            ApiResponse<ProviderListingEditorDTO>.self,
            from: Data(
                ListingDeletionFixtures.editorJSON(id: id, deleted: true).utf8
            )
        )
        guard let value = response.data else {
            throw NetworkError.invalidResponse
        }
        return value
    }
    func submit(id: String) async throws -> ProviderListingEditorDTO {
        throw NetworkError.invalidResponse
    }
}
