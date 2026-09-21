//
//  AuthEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

enum AuthEndpoint {
    case register(RegisterRequest)
    case login(LoginRequest)
    case forgotPassword(ForgotPasswordRequest)
    case resetPassword(ResetPasswordRequest)
    case verifyForgotPasswordOTP(VerifyForgotPasswordOTPRequest)
}
extension AuthEndpoint: Endpoint {
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword: return "/auth/reset-password"
        case .verifyForgotPasswordOTP: return "/auth/forgot-password/verify"
        }

    }
    var method: HttpMethod {
        switch self {
        case .login, .register, .forgotPassword, .verifyForgotPasswordOTP,
            .resetPassword:
            return .post
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .register(let request): .json(request)
        case .login(let request): .json(request)
        case .verifyForgotPasswordOTP(let request): .json(request)
        case .resetPassword(let request): .json(request)
        case .forgotPassword(let request): .json(request)
        }
    }
    var requiresAuth: Bool {
        false
    }
    var queryItems: [URLQueryItem]? {
        nil
    }
}
