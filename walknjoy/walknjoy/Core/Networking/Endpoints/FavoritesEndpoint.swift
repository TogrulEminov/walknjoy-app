//
//  FavoritesEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

enum FavoritesEndpoint {
    case addFavorites(String)
    case deleteFavorites(String)
    case getFavorites(limit: Int, page: Int, locale: String)
}
extension FavoritesEndpoint: Endpoint {
    var baseURL: String {
        APIConfig.baseURL
    }
    var headers: [String: String]? {
        nil
    }
    var path: String {
        switch self {
        case .addFavorites(let id): "/favorites/\(id)"
        case .deleteFavorites(let id): "/favorites/\(id)"
        case .getFavorites: "/favorites"
        }
    }

    var httpBody: RequestBody {
        .none
    }
    var queryItems: [URLQueryItem]? {
        guard case let .getFavorites(limit, page, locale) = self else { return nil }
        return [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "locale", value: locale)
        ]
    }
    var method: HttpMethod {
        switch self {
        case .addFavorites: .post
        case .deleteFavorites: .delete
        case .getFavorites: .get
        }
    }
    var requiresAuth: Bool {
        true
    }
}
