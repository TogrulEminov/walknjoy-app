//
//  FileUploadMode.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

enum FileUploadMode: Equatable {
    case single
    case multiple(maxCount: Int)

    var maxCount: Int {
        switch self {
        case .single: return 1
        case .multiple(let maxCount): return maxCount
        }
    }
}
