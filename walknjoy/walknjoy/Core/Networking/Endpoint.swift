//
//  Endpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

nonisolated protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HttpMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var httpBody: RequestBody { get }
    var requiresAuth: Bool { get }
    var usesOptionalAuth: Bool { get }
}

nonisolated extension Endpoint {
    var usesOptionalAuth: Bool { false }
    var baseURL: String {
        APIConfig.baseURL
    }

    var headers: [String: String]? {
        [
            HttpHeader.accept: ContentType.applicationJson
        ]
    }
    var queryItems: [URLQueryItem] { [] }
    var httpBody: RequestBody {
        .none
    }
    var requiresAuth: Bool {
        false
    }
}

nonisolated extension Endpoint {

    func makeRequest() throws -> URLRequest {
        guard
            var components = URLComponents(
                string: baseURL + path
            )
        else {
            throw NetworkError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue

        headers?.forEach { key, value in
            request.setValue(
                value,
                forHTTPHeaderField: key
            )
        }

        switch httpBody {

        case .none:
            break

        case .json(let body):
            do {
                request.httpBody = try JSONEncoder().encode(body)

                request.setValue(
                    ContentType.applicationJson,
                    forHTTPHeaderField: HttpHeader.contentType
                )

            } catch {
                throw NetworkError.encodingError
            }

        case .data(let data, let contentType):
            request.httpBody = data

            request.setValue(
                contentType,
                forHTTPHeaderField: HttpHeader.contentType
            )
        }

        return request
    }
}

nonisolated extension Endpoint {
    func makeQueryItems(
        _ parameters: [String: CustomStringConvertible?]
    ) -> [URLQueryItem] {
        parameters.compactMap { key, value in
            guard let value else {
                return nil
            }

            return URLQueryItem(
                name: key,
                value: value.description
            )
        }
    }
}
