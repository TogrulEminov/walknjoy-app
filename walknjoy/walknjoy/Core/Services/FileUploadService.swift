//
//  FileUploadService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import Foundation

nonisolated protocol FileUploadServiceProtocol {
    func uploadOne(_ input: UploadFileInput) async throws -> UploadedFile
    func deleteOne(
        id: String
    ) async throws
}

nonisolated final class FileUploadService: FileUploadServiceProtocol {
    private let networkService: NetworkingService

    init(networkService: NetworkingService? = nil) {
        self.networkService = networkService ?? DefaultNetworkService()
    }
    func deleteOne(
        id: String
    ) async throws {

        let response: ApiResponse<DeleteFileResponse> =
            try await networkService.request(
                enpoint: FileEndpoint.delete(id: id),
                responseType: ApiResponse<DeleteFileResponse>.self
            )

        guard response.data?.deleted == true else {
            throw NetworkError.invalidResponse
        }
    }
    func uploadOne(_ input: UploadFileInput) async throws -> UploadedFile {
        let response: ApiResponse<UploadedFile> =
            try await networkService.request(
                enpoint: FileEndpoint.upload(input),
                responseType: ApiResponse<UploadedFile>.self
            )

        guard let file = response.data else {
            throw NetworkError.invalidResponse
        }

        return file
    }
}
