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

    func verifyForgotPasswordOTP(
        request: VerifyForgotPasswordOTPRequest
    ) async throws -> VerifyForgotPasswordOTPResponse

    func resetPassword(
        request: ResetPasswordRequest
    ) async throws
}

final class AuthService: AuthServiceProtocol {
    private let tokenStorage: TokenStorageProtocol
    private let networkService: NetworkingService
    init(
        networkService: NetworkingService = DefaultNetworkService(),
        tokenStorage: TokenStorageProtocol = TokenStorage()
    ) {
        self.networkService = networkService
        self.tokenStorage = tokenStorage
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
        try tokenStorage.save(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken
        )
        return data
    }

}
