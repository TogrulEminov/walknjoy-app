//
//  AuthEndpoint.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

enum AuthEndpoint {
    case requestPasswordChange(ChangePasswordRequest)
    case verifyPasswordChange(ChangePasswordVerification)
    case changePassword(ChangePasswordInput)
    case register(RegisterRequest)
    case login(LoginRequest)
    case forgotPassword(ForgotPasswordRequest)
    case resetPassword(ResetPasswordRequest)
    case refresh(RefreshTokenRequest)
    case me
    case logout(LogoutRequest)

    case verifyForgotPasswordOTP(VerifyForgotPasswordOTPRequest)
}
extension AuthEndpoint: Endpoint {
    var path: String {
        switch self {
        case .requestPasswordChange: return "/auth/change-password/request"
        case .verifyPasswordChange: return "/auth/change-password/verify"
        case .changePassword: return "/auth/change-password"
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .me:
            return "/auth/me"
        case .register:
            return "/auth/register"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword: return "/auth/reset-password"
        case .verifyForgotPasswordOTP: return "/auth/forgot-password/verify"
        case .refresh: return "/auth/refresh"
        }

    }
    var method: HttpMethod {
        switch self {
        case .login, .register, .forgotPassword, .verifyForgotPasswordOTP,
            .refresh, .logout,
            .resetPassword:
            return .post
        case .requestPasswordChange, .verifyPasswordChange: return .post
        case .changePassword: return .patch
        case .me: return .get
        }
    }
    var httpBody: RequestBody {
        switch self {
        case .requestPasswordChange(let request): .json(request)
        case .verifyPasswordChange(let request): .json(request)
        case .changePassword(let request): .json(request)
        case .register(let request): .json(request)
        case .me: .none
        case .login(let request): .json(request)
        case .logout(let request): .json(request)
        case .verifyForgotPasswordOTP(let request): .json(request)
        case .refresh(let request): .json(request)
        case .resetPassword(let request): .json(request)
        case .forgotPassword(let request): .json(request)
        }
    }
    var requiresAuth: Bool {
        switch self {
        case .me, .logout, .requestPasswordChange, .verifyPasswordChange, .changePassword: return true
            
        default: return false
        }
    }
    var queryItems: [URLQueryItem]? {
        nil
    }
}
