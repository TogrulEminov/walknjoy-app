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
    case getFavorites
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
        switch self {
        case .getFavorites: .none
        case .addFavorites(let id): .json(id)
        case .deleteFavorites(let id): .json(id)
        }
    }
    var queryItems: [URLQueryItem]? {
        nil
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
