//
//  ListingEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import Foundation

enum ListingEndpoint {
    case getListings(ListingQuery)
    case getListing(slug: String, locale: String)
}

extension ListingEndpoint: Endpoint {
    var baseURL: String {
        APIConfig.baseURL
    }
    var path: String {
        switch self {
        case .getListings:
            "/listings"
        case .getListing(let slug, _):
            "/listings/\(slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/?#"))) ?? slug)"
        }
    }
    var method: HttpMethod {
        switch self {
        case .getListings, .getListing:
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
        case .getListing(_, let locale):
            return [URLQueryItem(name: "locale", value: locale)]
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .getListings, .getListing: .none
        }
    }

    var requiresAuth: Bool {
        false
    }
}
