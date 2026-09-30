import SwiftUI

struct CategoryCard: View {
    let category: CategoryModel
    let destination: HomeNavigationRoute

    var body: some View {
        NavigationLink(value: destination) {
            ZStack(alignment: .bottomLeading) {
                RemoteImageView(url: ImageURL.make(path: category.imageFile?.url)) {}

                LinearGradient(
                    colors: [.clear, Color.brandInk.opacity(0.94)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                Text(category.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            }
            .frame(width: 112, height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.border.opacity(0.7), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
