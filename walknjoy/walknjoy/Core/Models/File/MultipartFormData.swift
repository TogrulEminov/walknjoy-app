//
//  MultipartFormData.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

struct MultipartFormData {
    let boundary: String
    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    var contentType: String {
        "\(ContentType.multipartFormData); boundary=\(boundary)"
    }

    func createFile(
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString(
            """
            Content-Disposition: form-data; name="\(fieldName)"; filename="\(fileName)"\r\n
            """
        )
        
        body.appendString(
            "\(HttpHeader.contentType): \(mimeType)\r\n\r\n"
        )
        
        body.append(fileData)
        
        body.appendString("\r\n")
        
        body.appendString("--\(boundary)--\r\n")

        return body
    }
}
extension Data {

    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }

        append(data)
    }
}
