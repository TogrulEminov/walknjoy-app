//
//  ForgotPasswordState.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

enum ForgotPasswordState: Equatable {
    case idle
    case loading
    case success(
        expiresInSeconds: Int,
        resendAvailableInSeconds: Int
    )
    case error(String)
}
