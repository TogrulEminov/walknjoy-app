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
    let details: JSONValue?
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }
}

struct APIRequestFailure: LocalizedError {
    let error: ApiError
    var fieldErrors: [String: String] {
        guard case .array(let entries) = error.details else { return [:] }
        var fields: [String: String] = [:]
        for entry in entries {
            if case .object(let values) = entry,
               case .string(let field) = values["field"],
               case .string(let message) = values["message"] { fields[field] = message }
        }
        return fields
    }
    var errorDescription: String? {
        let details = error.details.map(messages) ?? []
        return ([error.message] + details).joined(separator: "\n")
    }
    private func messages(_ value: JSONValue) -> [String] {
        switch value {
        case .string(let text): return [text]
        case .array(let values): return values.flatMap(messages)
        case .object(let values):
            if case .string(let message) = values["message"] {
                return [message]
            }
            return values.keys.sorted().compactMap { key -> [String]? in
                guard let value = values[key] else { return nil }
                return messages(value).map { "\(key): \($0)" }
            }
            .flatMap { $0 }
        default: return []
        }
    }
}
