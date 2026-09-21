//
//  ApiErrorResponse.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

struct ApiErrorResponse: Decodable {
    let success: Bool
    let error: ApiError
}

struct ApiError: Decodable {
    let code: String
    let message: String
}
