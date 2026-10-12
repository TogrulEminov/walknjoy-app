//
//  TokenStorage.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import Foundation

nonisolated protocol TokenStorageProtocol {
    var accessToken: String? { get }
    var refreshToken: String? { get }

    func save(accessToken: String, refreshToken: String) throws
    func updateAccessToken(_ accessToken: String) throws
    func clear() throws
}

nonisolated final class TokenStorage: TokenStorageProtocol {
    private static let lock = NSRecursiveLock()

    private enum Keys {
        static let accessToken = "auth.accessToken"
        static let refreshToken = "auth.refreshToken"
    }
    private let keychain: KeychainService

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    var accessToken: String? {
        readToken(for: Keys.accessToken)

    }
    var refreshToken: String? {
        readToken(for: Keys.refreshToken)

    }
    func save(accessToken: String, refreshToken: String) throws {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard
            let accessData = accessToken.data(using: .utf8),
            let refreshData = refreshToken.data(using: .utf8)

        else { throw KeychainServiceError.invalidData }

        try keychain.save(accessData, for: Keys.accessToken)
        try keychain.save(refreshData, for: Keys.refreshToken)
    }

    func updateAccessToken(_ accessToken: String) throws {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard let data = accessToken.data(using: .utf8) else {
            throw KeychainServiceError.invalidData
        }
        try keychain.save(data, for: Keys.accessToken)
    }
    func clear() throws {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        try keychain.delete(for: Keys.accessToken)
        try keychain.delete(for: Keys.refreshToken)
    }
    private func readToken(for key: String) -> String? {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard let data = try? keychain.read(for: key) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
