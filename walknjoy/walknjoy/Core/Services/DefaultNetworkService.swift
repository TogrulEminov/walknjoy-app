//
//  DefaultNetworkService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

final class DefaultNetworkService: NetworkingService {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = .apiDecoder
    ) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(
        enpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T {

        let request = try enpoint.makeRequest()

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {

            if error.code == .notConnectedToInternet {
                throw NetworkError.noInternet
            }

            throw NetworkError.unknown(error)

        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG
            print("STATUS CODE:", httpResponse.statusCode)
            print(
                "RESPONSE:",
                String(data: data, encoding: .utf8) ?? "EMPTY"
            )
        #endif

        guard (200...299).contains(httpResponse.statusCode) else {

            if let apiError = try? decoder.decode(
                ApiErrorResponse.self,
                from: data
            ) {
                throw NetworkError.from(
                    code: apiError.error.code,
                    message: apiError.error.message,
                    statusCode: httpResponse.statusCode
                )
            }

            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode
            )
        }

        do {
            return try decoder.decode(
                responseType,
                from: data
            )
        } catch {

            #if DEBUG
                print("DECODING ERROR:", error)
            #endif

            throw NetworkError.decodingError
        }
    }
}
