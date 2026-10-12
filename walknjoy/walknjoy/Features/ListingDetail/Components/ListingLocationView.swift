import SwiftUI

struct ListingLocationView: View {
    let location: ListingLocation
    var body: some View {
        ListingDetailSection(title: "listing.detail.location") {
            ListingDetailCard {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.brandYellow.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.brandYellow)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            ListingDetailFormatting.location(location).isEmpty
                                ? location.countryCode
                                : ListingDetailFormatting.location(location)
                        )
                        .font(.headline)
                        .foregroundStyle(Color.titleText)

                        if let address = location.addressLine, !address.isEmpty
                        {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(Color.descriptionText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }
}
