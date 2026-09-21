//
//  ResetPasswordState.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

enum ResetPasswordState: Equatable {
    case loading
    case error(String)
    case success
    case idle
}
