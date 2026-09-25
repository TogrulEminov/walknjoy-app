//
//  UserDefaultsService.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import Foundation

protocol UserDefaultsServiceProtocol {
    var hasSeenOnboarding: Bool { get set }
    var selectedLanguage: AppLanguage { get set }
    var selectedMode: Mode { get set }
}
final class UserDefaultsService: UserDefaultsServiceProtocol {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let selectedLanguage = "selectedLanguage"
        static let selectedMode = "selectedMode"
    }

    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

    }

    var hasSeenOnboarding: Bool {
        get {
            defaults.bool(forKey: Keys.hasSeenOnboarding)
        }
        set {
            defaults.set(newValue, forKey: Keys.hasSeenOnboarding)
        }
    }
    var selectedMode: Mode {
        get {
            guard
                let value = defaults.string(forKey: Keys.selectedMode),
                let mode = Mode(rawValue: value)
            else {
                return .system
            }

            return mode
        }
        set {
            defaults.set(
                newValue.rawValue,
                forKey: Keys.selectedMode
            )
        }
    }
    var selectedLanguage: AppLanguage {
        get {
            guard
                let value = defaults.string(forKey: Keys.selectedLanguage),
                let language = AppLanguage(rawValue: value)
            else { return .az }

            return language
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedLanguage)
        }
    }
}
