//
//  FileUploadItem.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

struct UploadFileItem: Identifiable, Equatable {

    let id: UUID
    let previewData: Data

    var uploadedFile: UploadedFile?
    var state: UploadFileItemState

    init(
        id: UUID = UUID(),
        previewData: Data,
        uploadedFile: UploadedFile? = nil,
        state: UploadFileItemState = .idle
    ) {
        self.id = id
        self.previewData = previewData
        self.uploadedFile = uploadedFile
        self.state = state
    }
}
