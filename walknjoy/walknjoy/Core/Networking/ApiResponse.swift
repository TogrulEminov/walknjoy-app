//
//  ApiResponse.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let meta: PaginationMeta?
}

typealias APIResponse<T: Decodable> = ApiResponse<T>

struct PaginatedResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: [T]
    let meta: PaginationMeta
}

struct PaginationMeta: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    var hasNextPage: Bool { page < totalPages }

    init(page: Int, limit: Int, total: Int, totalPages: Int) {
        self.page = page; self.limit = limit; self.total = total; self.totalPages = totalPages
    }

    private enum CodingKeys: String, CodingKey { case page, limit, pageSize, total, totalPages }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        page = try c.decode(Int.self, forKey: .page)
        limit = try c.decodeIfPresent(Int.self, forKey: .pageSize) ?? c.decode(Int.self, forKey: .limit)
        total = try c.decode(Int.self, forKey: .total)
        totalPages = try c.decode(Int.self, forKey: .totalPages)
    }
}
