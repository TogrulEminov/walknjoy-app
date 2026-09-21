//
//  LoginViewState.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation
enum LoginViewState:Equatable {
    case idle
    case loading
    case success
    case error(String)
}
