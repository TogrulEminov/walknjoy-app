//
//  LanguageSelectionView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            content
            Spacer()
            continueButton
        }.padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 16)
            .background(Color(.systemBackground))
    }
}
extension LanguageSelectionView {
    private var header: some View {
        HStack {
            Image("logo-colorfull").resizable().scaledToFit().frame(width: 150)
            Spacer()
        }
    }
}
extension LanguageSelectionView {
    private var languageList: some View {
        ForEach(AppLanguage.allCases) { language in
            LanguageOptionView(
                language: language,
                isSelected: appState.language == language
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.selectLanguage(language)
                }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("language.title").font(.system(size: 28, weight: .bold))
                Text("language.subtitle").font(.system(size: 15))
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            languageList
        }
    }
}

extension LanguageSelectionView {

    private var continueButton: some View {
        Button {
            appState.finishLanguageSelection()
        } label: {

            HStack(spacing: 10) {

                Text("language.continue")
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )

                Image(systemName: "arrow.right")
            }
            .foregroundStyle(AppColors.navy)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.yellow)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }
}
