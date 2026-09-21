//
//  RegisterViewState.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

enum RegisterViewState:Equatable {
    case idle
    case loading
    case success
    case error(String)
}
