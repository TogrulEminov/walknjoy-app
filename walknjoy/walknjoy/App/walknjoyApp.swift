import SwiftUI

@main
struct walknjoyApp: App {
    @State private var appState: AppState

    init() {
        let preferences = UserDefaultsService()
        _appState = State(initialValue: AppState(preferences: preferences))
    }
    var body: some Scene {
        WindowGroup {
            AppView().environment(appState).environment(
                \.locale,
                appState.language.locale
            )

        }
    }
}
