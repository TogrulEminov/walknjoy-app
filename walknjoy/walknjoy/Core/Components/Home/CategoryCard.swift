import SwiftUI

struct CategoryCard: View {
    let category: CategoryModel
    let onTap: () -> Void

    private let cardWidth: CGFloat = 112
    private let cardHeight: CGFloat = 132
    private let radius: CGFloat = 12

    var body: some View {
        Button(action: onTap) {
            Color.clear
                .frame(width: cardWidth, height: cardHeight)
                .overlay {
                    RemoteImageView(
                        url: ImageURL.make(path: category.imageFile?.url)
                    ) {}
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                }
                .overlay {
                    LinearGradient(
                        colors: [.clear, Color.brandInk.opacity(0.94)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .padding(10)
                        .frame(width: cardWidth, alignment: .leading)
                }
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Color.border.opacity(0.7), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
