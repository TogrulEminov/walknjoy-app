//
//  UpdateAvatarInput.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//
import Foundation

nonisolated struct UpdateAvatarInput: Encodable {
    let fileId: String
    let altText: String?
    init(fileId: String, altText: String?) {
        self.fileId = fileId
        self.altText = altText
    }
}
