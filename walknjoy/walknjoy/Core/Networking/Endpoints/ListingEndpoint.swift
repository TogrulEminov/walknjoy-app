//
//  ListingEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import Foundation

nonisolated enum ListingEndpoint {
    case getListingByID(id: String, locale: String)
    case getListings(ListingQuery)
    case getListing(
        slug: String,
        locale: String,
        includeCustomerToken: Bool = false
    )
}

nonisolated extension ListingEndpoint: Endpoint {
    var baseURL: String {
        APIConfig.baseURL
    }
    var path: String {
        switch self {
        case .getListingByID(let id, _):
            "/listings/id/\(id)"
        case .getListings:
            "/listings"
        case .getListing(let slug, _, _):
            "/listings/\(slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/?#%"))) ?? slug)"
        }
    }
    var method: HttpMethod {
        switch self {
        case .getListings, .getListing, .getListingByID:
            .get
        }
    }
    var headers: [String: String]? {
        nil
    }
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getListings(let query):
            return query.queryItems()
        case .getListingByID(_, let locale), .getListing(_, let locale, _):
            return [URLQueryItem(name: "locale", value: locale)]
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .getListings, .getListing, .getListingByID: .none
        }
    }

    var usesOptionalAuth: Bool {
        if case .getListing(_, _, let includeToken) = self {
            return includeToken
        }
        if case .getListingByID = self { return true }
        return false
    }

    var requiresAuth: Bool {
        false
    }
}
