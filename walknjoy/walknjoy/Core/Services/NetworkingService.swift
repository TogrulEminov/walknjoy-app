//
//  NetworkingService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

protocol NetworkingService {
    func request<T: Decodable>(enpoint: Endpoint, responseType: T.Type)
        async throws -> T
}
