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

struct PaginationMeta: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}
