import SwiftUI

struct ListingAmenitiesView: View {
    let amenities: [AmenityModel]
    var body: some View {
        if !amenities.isEmpty {
            ListingDetailSection(title: "listing.detail.amenities") {
                EqualHeightAmenitiesLayout {
                    ForEach(amenities) { amenity in
                        Label(
                            amenity.name,
                            systemImage: amenity.icon.flatMap {
                                UIImage(systemName: $0) == nil ? nil : $0
                            } ?? "checkmark.circle"
                        )
                        .font(.subheadline).foregroundStyle(Color.titleText)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .leading
                        )
                        .padding(10)
                        .background(
                            Color.appBackground,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14).stroke(
                                Color.borderColor,
                                lineWidth: 1
                            )
                        }
                    }
                }
            }
        }
    }
}


private struct EqualHeightAmenitiesLayout: Layout {
    private let spacing: CGFloat = 10
    private let minimumWidth: CGFloat = 140

    private func dimensions(width: CGFloat, subviews: Subviews) -> (columns: Int, cellWidth: CGFloat, cellHeight: CGFloat) {
        let columns = max(1, Int((width + spacing) / (minimumWidth + spacing)))
        let cellWidth = max(0, (width - CGFloat(columns - 1) * spacing) / CGFloat(columns))
        let cellHeight = subviews.map {
            $0.sizeThatFits(ProposedViewSize(width: cellWidth, height: nil)).height
        }.max() ?? 0
        return (columns, cellWidth, cellHeight)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let width = proposal.width ?? minimumWidth
        let grid = dimensions(width: width, subviews: subviews)
        let rows = (subviews.count + grid.columns - 1) / grid.columns
        return CGSize(width: width, height: CGFloat(rows) * grid.cellHeight + CGFloat(rows - 1) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let grid = dimensions(width: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let column = index % grid.columns
            let row = index / grid.columns
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(column) * (grid.cellWidth + spacing),
                            y: bounds.minY + CGFloat(row) * (grid.cellHeight + spacing)),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: grid.cellWidth, height: grid.cellHeight)
            )
        }
    }
}
