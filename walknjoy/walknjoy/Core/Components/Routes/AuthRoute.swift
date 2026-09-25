//
//  AuthRoute.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 18.09.26.
//

import Foundation

enum AuthRoute: Hashable {
    case login
    case register
    case forgotPassword
    case otp(
        email: String,
        expireTime:Int,
        resendAvailableInSeconds: Int
    )


    case resetPassword(
        resetToken: String
    )
}
