//
//  NetworkingService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

@MainActor
protocol NetworkingService {
    func request<T: Decodable>(enpoint: Endpoint, responseType: T.Type)
        async throws -> T
    func requestData(enpoint: Endpoint) async throws -> Data
}
