import Foundation

@MainActor
final class DefaultNetworkService: NetworkingService {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let tokenStorage: TokenStorageProtocol

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder? = nil,
        tokenStorage: TokenStorageProtocol? = nil
    ) {
        self.session = session
        self.decoder = decoder ?? .apiDecoder
        self.tokenStorage = tokenStorage ?? TokenStorage()
    }

    func request<T: Decodable>(
        enpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T {

        var request = try enpoint.makeRequest()

        // MARK: - Authorization

        if enpoint.requiresAuth {

            guard let accessToken = tokenStorage.accessToken else {
                throw NetworkError.unauthorized
            }

            request.setValue(
                "\(HttpHeader.bearer) \(accessToken)",
                forHTTPHeaderField: HttpHeader.authorization
            )
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(
                for: request
            )
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
            print(
                "STATUS CODE:",
                httpResponse.statusCode
            )
        #endif

        guard
            (200...299).contains(
                httpResponse.statusCode
            )
        else {

            if let apiError = try? decoder.decode(
                ApiErrorResponse.self,
                from: data
            ) {
                if enpoint.path.hasPrefix("/provider/listings") {
                    throw APIRequestFailure(error: apiError.error)
                }
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
                if enpoint.path.hasPrefix("/notifications") {
                    print("Notification response decoding failed")
                } else {
                    print("DECODING ERROR:", error)
                }
            #endif

            throw NetworkError.decodingError
        }
    }
}
