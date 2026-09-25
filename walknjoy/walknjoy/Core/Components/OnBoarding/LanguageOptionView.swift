import SwiftUI

struct LanguageOptionView: View {

    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(
            action: {
                action()
            },
            label: {
                HStack(spacing: 14) {
                    Text(language.flag)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(language.title)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(Color.titleText)

                        Text(language.shortTitle)
                            .font(
                                .system(
                                    size: 12,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(Color.descriptionText)
                    }

                    Spacer()

                    selectionIndicator
                }
                .padding(.horizontal, 16)
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? Color.titleText.opacity(0.10)
                        : Color.surfaceBackground
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? Color.brandYellow
                                : Color.clear,
                            lineWidth: 1.5
                        )
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
        )
        .buttonStyle(.plain)
    }
}

extension LanguageOptionView {

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected
                        ? Color.brandYellow
                        : Color.borderColor.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(Color.brandYellow)
                    .frame(width: 12, height: 12)
            }
        }
    }
}
