//
//  UploadFile.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

struct UploadedFile: Decodable, Identifiable, Equatable {
    let id: String
    let url: String
    let originalName: String
    let mimeType: String
    let sizeBytes: Int
}
