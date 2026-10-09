//
//  AuthService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 19.09.26.
//

import Foundation

protocol AuthServiceProtocol {
    func register(request: RegisterRequest) async throws -> RegisterResponse
    func login(request: LoginRequest) async throws -> LoginResponse
    func forgotPassword(
        request: ForgotPasswordRequest
    ) async throws -> ForgotPasswordResponse
    func logout() async throws
    func verifyForgotPasswordOTP(
        request: VerifyForgotPasswordOTPRequest
    ) async throws -> VerifyForgotPasswordOTPResponse

    func resetPassword(
        request: ResetPasswordRequest
    ) async throws

    func refresh() async throws
    func me() async throws -> AuthUser
    func restoreSession() async throws
}

final class AuthService: AuthServiceProtocol {
    private let tokenStorage: TokenStorageProtocol
    private let networkService: NetworkingService
    init(
        networkService: NetworkingService? = nil,
        tokenStorage: TokenStorageProtocol? = nil
    ) {
        self.networkService = networkService ?? DefaultNetworkService()
        self.tokenStorage = tokenStorage ?? TokenStorage()
    }

    func forgotPassword(request: ForgotPasswordRequest) async throws
        -> ForgotPasswordResponse
    {
        let response: ApiResponse<ForgotPasswordResponse> =
            try await networkService.request(
                enpoint: AuthEndpoint.forgotPassword(request),
                responseType: ApiResponse<ForgotPasswordResponse>.self
            )
        guard let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func logout() async throws {
        guard let refreshToken = tokenStorage.refreshToken else {
            throw NetworkError.unauthorized
        }

        let request = LogoutRequest(
            refreshToken: refreshToken
        )

        let _: ApiResponse<EmptyResponse> = try await networkService.request(
            enpoint: AuthEndpoint.logout(request),
            responseType: ApiResponse<EmptyResponse>.self
        )

        try tokenStorage.clear()
    }
    func verifyForgotPasswordOTP(request: VerifyForgotPasswordOTPRequest)
        async throws -> VerifyForgotPasswordOTPResponse
    {
        let response: ApiResponse<VerifyForgotPasswordOTPResponse> =
            try await networkService.request(
                enpoint: AuthEndpoint.verifyForgotPasswordOTP(request),
                responseType: ApiResponse<VerifyForgotPasswordOTPResponse>.self
            )

        guard let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func resetPassword(request: ResetPasswordRequest) async throws {
        let _: ApiResponse<EmptyResponse> = try await networkService.request(
            enpoint: AuthEndpoint.resetPassword(request),
            responseType: ApiResponse<EmptyResponse>.self
        )
    }
    func register(request: RegisterRequest) async throws -> RegisterResponse {
        let response: ApiResponse<RegisterResponse> =
            try await networkService.request(
                enpoint: AuthEndpoint.register(request),
                responseType: ApiResponse<RegisterResponse>.self
            )

        guard let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func login(request: LoginRequest) async throws -> LoginResponse {
        let response: ApiResponse<LoginResponse> =
            try await networkService.request(
                enpoint: AuthEndpoint.login(request),
                responseType: ApiResponse<LoginResponse>.self
            )

        guard let data = response.data else {
            throw NetworkError.invalidResponse
        }
        try validateMobileAccess(role: data.user.role)
        try tokenStorage.save(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken
        )
        return data
    }

    func refresh() async throws {
        guard let refreshToken = tokenStorage.refreshToken else {
            throw NetworkError.unauthorized
        }
        let request = RefreshTokenRequest(refreshToken: refreshToken)

        let response: ApiResponse<RefreshTokenResponse> =
            try await networkService.request(
                enpoint: AuthEndpoint.refresh(request),
                responseType: ApiResponse<RefreshTokenResponse>.self
            )

        guard let data = response.data else {
            throw NetworkError.invalidResponse
        }
        // A refresh begun by a previous session must not overwrite a newer login/logout.
        guard tokenStorage.refreshToken == refreshToken else {
            throw NetworkError.unauthorized
        }
        try tokenStorage.save(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken
        )
    }
    func me() async throws -> AuthUser {
        let response: ApiResponse<AuthUser> = try await networkService.request(
            enpoint: AuthEndpoint.me,
            responseType: ApiResponse<AuthUser>.self
        )

        guard let user = response.data else {
            throw NetworkError.invalidResponse
        }
        try validateMobileAccess(role: user.role)
        return user
    }

    func restoreSession() async throws {
        guard tokenStorage.refreshToken != nil else {
            throw NetworkError.unauthorized
        }
        do {
            try await refresh()
            _ = try await me()
        } catch {
            // A refreshed token alone is not proof of an allowed mobile account.
            try? tokenStorage.clear()
            throw error
        }
    }

    private func validateMobileAccess(role: String) throws {
        do {
            try MobileAccountAccess.validate(role: role)
        } catch {
            try tokenStorage.clear()
            throw error
        }
    }
}

@MainActor
protocol ChangePasswordServiceProtocol {
    func requestPasswordChange(currentPassword: String) async throws
        -> ChangePasswordChallenge
    func verifyPasswordChange(code: String) async throws
        -> ChangePasswordAuthorization
    func changePassword(token: String, newPassword: String) async throws
}

extension AuthService: ChangePasswordServiceProtocol {
    func requestPasswordChange(currentPassword: String) async throws
        -> ChangePasswordChallenge
    {
        let response: ApiResponse<ChangePasswordChallenge> =
            try await networkService.request(
                enpoint: AuthEndpoint.requestPasswordChange(
                    .init(currentPassword: currentPassword)
                ),
                responseType: ApiResponse<ChangePasswordChallenge>.self
            )
        guard response.success, let data = response.data else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func verifyPasswordChange(code: String) async throws
        -> ChangePasswordAuthorization
    {
        let response: ApiResponse<ChangePasswordAuthorization> =
            try await networkService.request(
                enpoint: AuthEndpoint.verifyPasswordChange(.init(code: code)),
                responseType: ApiResponse<ChangePasswordAuthorization>.self
            )
        guard response.success, let data = response.data,
            !data.changePasswordToken.isEmpty
        else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func changePassword(token: String, newPassword: String) async throws {
        let response: ApiResponse<EmptyResponse> =
            try await networkService.request(
                enpoint: AuthEndpoint.changePassword(
                    .init(changePasswordToken: token, newPassword: newPassword)
                ),
                responseType: ApiResponse<EmptyResponse>.self
            )
        guard response.success else { throw NetworkError.invalidResponse }
    }
}
