//
//  AppView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

struct AppView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.flow {
            case .splash: SplashView()
            case .onboarding: OnboardingView()
            case .auth: AuthView()
            case .main: Text("main")
            case .languageSelection:
                LanguageSelectionView()
            }
        }.task {
            if appState.flow == .splash {
                await appState.start()
            }
        }
    }
}
