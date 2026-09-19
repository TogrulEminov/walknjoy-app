//
//  LanguageOptionView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//
import SwiftUI

struct LanguageOptionView: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(language.flag).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.title).font(
                        .system(size: 16, weight: .semibold)
                    ).foregroundStyle(AppColors.navy)
                    Text(language.shortTitle).font(
                        .system(size: 12, weight: .medium)
                    ).foregroundStyle(.secondary)
                }
                Spacer()
                selectionIndicator
            }.padding(.horizontal, 16)
                .frame(height: 72)
                .background(
                    isSelected
                        ? AppColors.yellow.opacity(0.10)
                        : Color(.secondarySystemBackground)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? AppColors.yellow
                                : Color.clear,
                            lineWidth: 1.5
                        )
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
        }
        .buttonStyle(.plain)
    }
}

extension LanguageOptionView {

    private var selectionIndicator: some View {
        ZStack {

            Circle()
                .stroke(
                    isSelected
                        ? AppColors.yellow
                        : Color.secondary.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(AppColors.yellow)
                    .frame(width: 12, height: 12)
            }
        }
    }
}
