import SwiftUI

struct ListingDescriptionView: View {
    let description: String
    @State private var expanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0

    var body: some View {
        ListingDetailSection(title: "listing.detail.about") {
            Text(description)
                .font(.subheadline).foregroundStyle(Color.descriptionText)
                .lineSpacing(3).lineLimit(expanded ? nil : 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    measuredText(lineLimit: nil) { fullHeight = $0 }
                    measuredText(lineLimit: 4) { collapsedHeight = $0 }
                }
            if fullHeight > collapsedHeight + 1 {
                Button(
                    expanded
                        ? "listing.detail.showLess" : "listing.detail.showMore"
                ) {
                    expanded.toggle()
                }
                .font(.subheadline.weight(.semibold)).tint(Color.titleText)
                .frame(minHeight: 44)
            }
        }
    }

    private func measuredText(
        lineLimit: Int?,
        onMeasure: @escaping (CGFloat) -> Void
    ) -> some View {
        Text(description)
            .font(.subheadline).lineSpacing(3).lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) {
                $0.size.height
            } action: {
                onMeasure($0)
            }
            .hidden()
            .accessibilityHidden(true)
    }
}
