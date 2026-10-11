//
//  AppView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

struct AppView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.flow {
            case .splash: SplashView()
            case .onboarding: OnboardingView()
            case .auth: AuthView()
            case .main: MainView()
            case .languageSelection:
                LanguageSelectionView()
            }
        }
        .environment(appState.notifications)
        .preferredColorScheme(appState.mode.colorScheme)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { appState.setAppActive(true) }
            else if phase == .background { appState.setAppActive(false) }
        }

        .task {
            if appState.flow == .splash {
                await appState.start()
            }
        }
    }
}
