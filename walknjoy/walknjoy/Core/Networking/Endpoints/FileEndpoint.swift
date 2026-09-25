//
//  FileEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

enum FileEndpoint {
    case upload(UploadFileInput)
    case delete(id: String)

}
extension FileEndpoint: Endpoint {
    var path: String {
        switch self {
        case .upload:
            return "/files"
        case .delete(let id):
            return "/files/\(id)"
        }
    }
    var method: HttpMethod {
        switch self {
        case .upload: return .post
        case .delete: return .delete
        }
    }
    var requiresAuth: Bool {
        return true
    }
    var httpBody: RequestBody {
        switch self {
        case .delete:
            return .none
        case .upload(let input):
            let multipart = MultipartFormData()
            let data = multipart.createFile(
                fieldName: "file",
                fileName: input.fileName,
                mimeType: input.mimeType,
                fileData: input.data
            )

            return .data(data, contentType: multipart.contentType)
        }
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
