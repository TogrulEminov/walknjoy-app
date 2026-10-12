//
//  RequestBody.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

nonisolated enum RequestBody {
    case none
    case json(Encodable)
    case data(Data, contentType: String)
}
