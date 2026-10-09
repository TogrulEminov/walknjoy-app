import SwiftUI

struct ListingHeaderView: View {
    @ScaledMetric(relativeTo: .title2) private var titleSize = 24.0
    let title: String
    let category: String?
    let type: ListingType
    let shortDescription: String?
    let rating: Rating?
    let location: ListingLocation?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                if let category = ReviewValidation.text(category) { Text(category) }
                else { Text(type.title) }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.titleText)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color.brandYellow.opacity(0.14), in: Capsule())

            Text(title)
                .font(.system(size: titleSize, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let location {
                Label(
                    ListingDetailFormatting.location(location).isEmpty
                        ? location.countryCode : ListingDetailFormatting.location(location),
                    systemImage: "mappin.and.ellipse"
                )
                .font(.subheadline).foregroundStyle(Color.descriptionText)
            }

            if let rating, rating.count > 0, let average = rating.average {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").foregroundStyle(Color.brandYellow)
                    Text(average.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.bold)
                    Rectangle().fill(Color.borderColor).frame(width: 1, height: 14)
                    Text(String(format: String(localized: "listing.detail.reviewCountFormat"), rating.count))
                        .foregroundStyle(Color.descriptionText)
                }
                .font(.subheadline)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }

            if let summary = ReviewValidation.text(shortDescription),
               summary.compare(title.trimmingCharacters(in: .whitespacesAndNewlines), options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame {
                Text(summary).font(.subheadline).foregroundStyle(Color.descriptionText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Color.titleText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
