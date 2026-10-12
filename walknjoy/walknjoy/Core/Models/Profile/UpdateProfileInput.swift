//
//  UpdateProfileInput.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import Foundation

nonisolated struct UpdateProfileInput: Encodable {
    let firstName: String?
    let lastName: String?
    let phone: String?
}
