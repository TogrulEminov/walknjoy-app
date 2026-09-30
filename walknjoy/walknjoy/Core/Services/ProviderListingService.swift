import Foundation

@MainActor protocol ProviderListingsManaging {
    func list(query: ProviderListingsQuery) async throws -> ApiResponse<
        [ProviderListingCardDTO]
    >
    func archive(id: String) async throws -> ProviderListingEditorDTO
    func submit(id: String) async throws -> ProviderListingEditorDTO
}

@MainActor final class ProviderListingService: ProviderListingsManaging {
    private let network: NetworkingService
    init(network: NetworkingService? = nil) {
        self.network = network ?? DefaultNetworkService()
    }

    func list(query: ProviderListingsQuery) async throws -> ApiResponse<
        [ProviderListingCardDTO]
    > {
        let response = try await network.request(
            enpoint: ProviderListingEndpoint.list(query),
            responseType: ApiResponse<[ProviderListingCardDTO]>.self
        )
        guard response.success, response.data != nil, response.meta != nil
        else { throw NetworkError.invalidResponse }
        return response
    }

    func get(id: String) async throws -> ProviderListingEditorDTO {
        try await listing(.get(id: id))
    }

    func create(_ input: CreateListingRequest) async throws
        -> ProviderListingEditorDTO
    {
        try await listing(.create(input))
    }

    func update(id: String, input: UpdateListingRequest) async throws
        -> ProviderListingEditorDTO
    {
        try await listing(.update(id: id, input: input))
    }

    func updatePrice(id: String, amount: Decimal, currency: ProviderCurrency) async throws -> ProviderListingEditorDTO {
        try await listing(.updatePrice(id: id, input: ProviderPriceUpdateRequest(basePrice: amount, currency: currency)))
    }

    func submit(id: String) async throws -> ProviderListingEditorDTO {
        try await listing(.submit(id: id))
    }

    func archive(id: String) async throws -> ProviderListingEditorDTO {
        try await listing(.archive(id: id))
    }

    func getDetails(id: String) async throws -> ProviderListingDetailsDTO {
        let response = try await network.request(
            enpoint: ProviderListingEndpoint.getDetails(id: id),
            responseType: ApiResponse<ProviderListingDetailsDTO>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func saveDetails(id: String, input: ListingDetailsInput) async throws {
        try await mutate(.details(id: id, input: input))
    }

    func addMedia(id: String, fileId: String, altText: String?) async throws
        -> ProviderListingEditorDTO.Media
    {
        let response = try await network.request(
            enpoint: ProviderListingEndpoint.addMedia(
                id: id,
                input: ProviderMediaRequest(
                    fileId: fileId,
                    altText: altText?.listingNonBlank
                )
            ),
            responseType: ApiResponse<ProviderListingEditorDTO.Media>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func uploadAndAddMedia(id: String, input: UploadFileInput, altText: String?) async throws {
        let uploaded = try await FileUploadService().uploadOne(input)
        _ = try await addMedia(id: id, fileId: uploaded.id, altText: altText)
    }

    func deleteMedia(id: String, mediaId: String) async throws {
        struct Deleted: Decodable {
            let id: String
            let deleted: Bool
        }
        let response = try await network.request(
            enpoint: ProviderListingEndpoint.deleteMedia(
                id: id,
                mediaId: mediaId
            ),
            responseType: ApiResponse<Deleted>.self
        )
        guard response.success, response.data?.id == mediaId,
            response.data?.deleted == true
        else { throw NetworkError.invalidResponse }
    }

    private func mutate(_ endpoint: ProviderListingEndpoint) async throws {
        let response = try await network.request(
            enpoint: endpoint,
            responseType: ApiResponse<JSONValue>.self
        )
        guard response.success else { throw NetworkError.invalidResponse }
    }

    func cities(locale: ListingLocale, countryCode: String = "AZ") async throws
        -> [ListingCity]
    {
        let response = try await network.request(
            enpoint: ListingTaxonomyEndpoint.cities(
                locale: locale,
                countryCode: countryCode
            ),
            responseType: ApiResponse<[ListingCity]>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func categories(type: ListingType?, locale: ListingLocale) async throws
        -> [CategoryModel]
    {
        let response = try await network.request(
            enpoint: CategoryEndpoint.filtered(
                type: type,
                locale: locale.rawValue
            ),
            responseType: ApiResponse<[CategoryModel]>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data.filter {
            !$0.isDeleted && (type == nil || $0.listingTypes.isEmpty
                || $0.listingTypes.contains(type!)
            )
        }
    }

    func amenities(type: ListingType, locale: ListingLocale) async throws
        -> [AmenityModel]
    {
        let response = try await network.request(
            enpoint: ListingTaxonomyEndpoint.amenities(
                type: type,
                locale: locale
            ),
            responseType: ApiResponse<[AmenityModel]>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data.filter {
            !$0.isDeleted && ($0.listingTypes.isEmpty || $0.listingTypes.contains(type))
        }
    }

    private func listing(_ endpoint: ProviderListingEndpoint) async throws
        -> ProviderListingEditorDTO
    {
        let response = try await network.request(
            enpoint: endpoint,
            responseType: ApiResponse<ProviderListingEditorDTO>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }
}
