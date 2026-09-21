import Foundation
import Observation

@MainActor
@Observable

final class AppState {
    var flow: Flow = .splash
    var mode: Mode = .light
    private let authService: AuthServiceProtocol

    private var preferences: UserDefaultsServiceProtocol
    var language: AppLanguage

    init(
        preferences: UserDefaultsServiceProtocol,
        authService: AuthServiceProtocol = AuthService()
    ) {
        self.preferences = preferences
        self.authService = authService

        self.mode = preferences.selectedMode
        self.language = preferences.selectedLanguage
    }
    func selectMode(_ mode: Mode) {
        self.mode = mode
        preferences.selectedMode = mode
    }
    func finishAuthentication() {
        flow = .main
    }
    func selectLanguage(_ language: AppLanguage) {
        self.language = language
    }
    func start() async {
        try? await Task.sleep(for: .seconds(1.5))

        guard preferences.hasSeenOnboarding else {
            flow = .onboarding
            return
        }

        do {
            try await authService.restoreSession()
 
            flow = .main

        } catch {
            // Session yoxdur və ya artıq etibarsızdır
            flow = .auth
        }
    }

    func finishOnboarding() {
        flow = .languageSelection
    }

    func finishLanguageSelection() {
        preferences.selectedLanguage = language
        preferences.hasSeenOnboarding = true
        flow = .auth
    }
}
