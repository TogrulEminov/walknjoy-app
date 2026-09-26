//
//  AdminCategories.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

enum AdminCategoriesEndpoint {
    case getCategories(page: Int, limit: Int)
    case getCategoriesById(id: String)
    case updateCategories(id: String)
    case deleteCategories(id: String)
}
extension AdminCategoriesEndpoint: Endpoint {
    var baseURL: String {
        APIConfig.baseURL
    }
    var headers: [String: String]? {
        nil
    }

    var path: String {
        switch self {
        case .deleteCategories(let id): "/admin/categories/\(id)"
        case .updateCategories(let id): "/admin/categories/\(id)"
        case .getCategoriesById(let id): "/admin/categories/\(id)"
        case .getCategories: "/admin/categories"
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .deleteCategories(let id): .json(id)
        case .getCategoriesById: .none
        case .getCategories: .none
        case .updateCategories(let id): .json(id)
        }
    }
    var queryItems: [URLQueryItem]? {
        guard case .getCategories(let limit, let page) = self else {
            return nil
        }
        return [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "page", value: String(page)),
        ]
    }
    var requiresAuth: Bool {
        true
    }
    var method: HttpMethod {
        switch self {
        case .deleteCategories: .delete
        case .updateCategories: .patch
        case .getCategoriesById: .get
        case .getCategories: .get
        }
    }
}
