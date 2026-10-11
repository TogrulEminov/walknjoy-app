//
//  R2ImaegeUrl.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import Foundation

enum ImageURL {

    static func make(path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        if let url = URL(string: path),
            url.scheme != nil
        {
            return url
        }

        let baseURL = APIConfig.imageUrl
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let cleanPath =
            path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        return URL(
            string: "\(baseURL)/\(cleanPath)"
        )
    }
}
