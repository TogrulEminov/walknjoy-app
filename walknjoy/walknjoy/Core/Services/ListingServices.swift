//
//  ListingServices.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import Foundation

protocol ListingServicesProtocol {
    func getListings(query: ListingQuery) async throws -> [ListingResponse]
    func searchListings(criteria: ListingSearchCriteria) async throws
        -> ListingsPage
    func getListing(slug: String, locale: String, includeCustomerToken: Bool)
        async throws -> Listing
}

struct ListingsPage {
    let listings: [PublicListing]
    let meta: PaginationMeta
}

@MainActor
final class ListingServices: ListingServicesProtocol {
    private let networkServices: NetworkingService

    init(
        networkService: NetworkingService? = nil
    ) {
        self.networkServices = networkService ?? DefaultNetworkService()
    }

    func getListing(
        slug: String,
        locale: String,
        includeCustomerToken: Bool = false
    ) async throws -> Listing {
        let response = try await networkServices.request(
            enpoint: ListingEndpoint.getListing(
                slug: slug,
                locale: locale,
                includeCustomerToken: includeCustomerToken
            ),
            responseType: ApiResponse<Listing>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func getListing(id: String, locale: String) async throws -> Listing {
        let response = try await networkServices.request(
            enpoint: ListingEndpoint.getListingByID(id: id, locale: locale),
            responseType: ApiResponse<Listing>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func getListings(query: ListingQuery) async throws -> [ListingResponse] {
        try await searchListings(criteria: query).listings
    }

    func searchListings(criteria: ListingSearchCriteria) async throws
        -> ListingsPage
    {
        let response = try await networkServices.request(
            enpoint: ListingEndpoint.getListings(criteria),
            responseType: ApiResponse<[PublicListing]>.self
        )

        guard response.success, let data = response.data,
            let meta = response.meta
        else {
            throw NetworkError.invalidResponse
        }
        return ListingsPage(listings: data, meta: meta)
    }
}
