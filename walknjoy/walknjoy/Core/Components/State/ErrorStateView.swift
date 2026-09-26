import SwiftUI

struct ErrorStateView: View {
    let title: LocalizedStringKey
    let message: String
    var retryTitle: LocalizedStringKey?
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            StateIconView(
                icon: "exclamationmark.triangle",
                tint: .errorColor, background: .errorColor
            )

            VStack(spacing: 10) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.titleText)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.descriptionText)
                    .lineSpacing(3)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            if let retryTitle, let onRetry {
                SubmitButton(title: retryTitle, icon: "arrow.clockwise", action: onRetry)
            }
        }
        .frame(maxWidth: 360)
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
