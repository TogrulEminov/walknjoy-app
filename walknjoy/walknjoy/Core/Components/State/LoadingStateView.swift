import SwiftUI

struct LoadingStateView: View {
    var message: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.iconColor)
                .frame(width: 64, height: 64)
                .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderColor.opacity(0.6), lineWidth: 1)
                }

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.descriptionText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 360)
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
