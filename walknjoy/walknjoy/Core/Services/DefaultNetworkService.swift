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

        #if DEBUG
        Self.logRequest(request)
        #endif

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

            #if DEBUG
            print("🌐 [Network] Transport error: \(error.code) — \(error.localizedDescription)")
            #endif

            if error.code == .notConnectedToInternet {
                throw NetworkError.noInternet
            }

            throw NetworkError.unknown(error)

        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            #if DEBUG
            print("🌐 [Network] Invalid response: expected HTTPURLResponse")
            #endif
            throw NetworkError.invalidResponse
        }

        #if DEBUG
        Self.logResponse(httpResponse, data: data)
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

            #if DEBUG
            print("🌐 [Network] Could not decode API error body; raw response is shown above.")
            #endif
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
            print("🌐 [Network] Decode failure: \(String(reflecting: error))")
            #endif
            throw NetworkError.decodingError(
                details: Self.decodingDetails(for: error)
            )
        }
    }

    private static func decodingDetails(for error: Error) -> String {
        func codingPath(_ context: DecodingError.Context) -> String {
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return path.isEmpty ? "root" : path
        }

        switch error {
        case DecodingError.typeMismatch(let type, let context):
            return "\(codingPath(context)) sahəsində \(type) tipli dəyər gözlənilirdi, cavab uyğun deyil."
        case DecodingError.valueNotFound(let type, let context):
            return "\(codingPath(context)) sahəsində \(type) dəyəri yoxdur."
        case DecodingError.keyNotFound(let key, let context):
            return "\(codingPath(context)).\(key.stringValue) sahəsi cavabda yoxdur."
        case DecodingError.dataCorrupted(let context):
            return "\(codingPath(context)) sahəsində məlumat pozulub: \(context.debugDescription)"
        default:
            return error.localizedDescription
        }
    }

    #if DEBUG
    private static let sensitiveKeys: Set<String> = [
        "authorization", "accesstoken", "refreshtoken", "token",
        "password", "currentpassword", "newpassword", "otp",
        "verificationcode", "resetcode", "email", "phone"
    ]

    private static func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<no URL>"
        print("🌐 [Network] ➡️ \(method) \(url)")
        let headers = (request.allHTTPHeaderFields ?? [:])
            .filter { $0.key.lowercased() != "authorization" }
        if !headers.isEmpty {
            print("🌐 [Network] Request headers: \(headers)")
        }
        if let body = request.httpBody {
            print("🌐 [Network] Request body (\(body.count) bytes):\n\(formattedJSON(body) ?? String(decoding: body, as: UTF8.self))")
        }
    }

    private static func logResponse(_ response: HTTPURLResponse, data: Data) {
        let url = response.url?.absoluteString ?? "<no URL>"
        print("🌐 [Network] ⬅️ HTTP \(response.statusCode) \(url)")
        if let body = formattedJSON(data) {
            print("🌐 [Network] Response body (\(data.count) bytes):\n\(body)")
        } else {
            print("🌐 [Network] Response body (\(data.count) bytes): \(String(decoding: data, as: UTF8.self))")
        }
    }

    private static func formattedJSON(_ data: Data) -> String? {
        guard var object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        object = redact(object)
        guard let safeData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
        ) else { return nil }
        return String(data: safeData, encoding: .utf8)
    }

    private static func redact(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, item in
                let normalizedKey = item.key
                    .lowercased()
                    .filter { $0.isLetter || $0.isNumber }
                result[item.key] = sensitiveKeys.contains(normalizedKey)
                    ? "<redacted>"
                    : redact(item.value)
            }
        }
        if let array = value as? [Any] {
            return array.map(redact)
        }
        return value
    }
    #endif
}
