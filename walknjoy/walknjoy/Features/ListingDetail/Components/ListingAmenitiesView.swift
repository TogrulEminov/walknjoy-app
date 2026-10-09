import SwiftUI

struct ListingAmenitiesView: View {
    let amenities: [AmenityModel]
    var body: some View {
        if !amenities.isEmpty {
            ListingDetailSection(title: "listing.detail.amenities") {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140), spacing: 10)],
                    spacing: 10
                ) {
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
                            minHeight: 24,
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
