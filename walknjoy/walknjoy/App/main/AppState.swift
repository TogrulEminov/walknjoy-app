import Observation

@MainActor
@Observable
final class AppState {

    enum Flow {
        case splash
        case onboarding
        case languageSelection
        case auth
        case main
    }

    var flow: Flow = .splash

    private var preferences: UserDefaultsServiceProtocol
    var language: AppLanguage

    init(preferences: UserDefaultsServiceProtocol, ) {
        self.preferences = preferences
        self.language = preferences.selectedLanguage
    }

    func selectLanguage(_ language: AppLanguage) {
        self.language = language
    }
    func start() async {
        try? await Task.sleep(for: .seconds(1.5))

        if preferences.hasSeenOnboarding {
            flow = .auth
        } else {
            flow = .onboarding
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
