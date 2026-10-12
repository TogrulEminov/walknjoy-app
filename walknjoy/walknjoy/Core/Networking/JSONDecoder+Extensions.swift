//
//  JSONDecoder+Extensions.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

nonisolated extension JSONDecoder {

    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { decoder in
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = fractional.date(
                from: dateString
            ) {
                return date
            }

            if let date = standard.date(
                from: dateString
            ) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }

        return decoder
    }
}
