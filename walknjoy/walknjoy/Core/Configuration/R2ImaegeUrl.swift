//
//  R2ImaegeUrl.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//


import Foundation

enum TMDBImageURL {
    static func make(path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }
        let urlString = "\(APIConfig.imageUrl)/\(path)"
        return URL(string: urlString)
    }
}
