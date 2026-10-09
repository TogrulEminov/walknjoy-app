import SwiftUI

struct ListingQuickInfoItem: View {
    let icon: String
    let value: String
    let title: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.body).foregroundStyle(
                Color.iconColor
            )
            Text(value).font(.headline).foregroundStyle(Color.titleText)
            Text(title).font(.caption).foregroundStyle(Color.descriptionText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(12)
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(
                Color.borderColor,
                lineWidth: 1
            )
        }
        .accessibilityElement(children: .combine)
    }
}
