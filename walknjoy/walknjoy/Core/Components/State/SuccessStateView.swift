import SwiftUI

struct SuccessStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var buttonTitle: LocalizedStringKey?
    var onButtonTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            StateIconView(icon: "checkmark")

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

            if let buttonTitle, let onButtonTap {
                SubmitButton(title: buttonTitle, action: onButtonTap)
            }
        }
        .frame(maxWidth: 360)
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
