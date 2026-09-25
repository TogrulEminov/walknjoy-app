//
//  OtpViewState.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation
enum OtpViewState: Equatable {
    case idle
    case loading
    case success(resetToken:String)
    case error(String)
    case resendSuccess(
        expiresInSeconds: Int,
        resendAvailableInSeconds: Int
    )
}
