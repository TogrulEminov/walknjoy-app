//
//  FileUploadState.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

enum UploadFileItemState: Equatable {
    case idle
    case uploading
    case uploaded
    case failed(String)

}
