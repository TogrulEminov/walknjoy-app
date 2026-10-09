import SwiftUI

struct ListingReviewsView: View {
    let rating: Rating?
    var body: some View {
        ListingDetailSection(title: "listing.detail.reviews") {
            if let rating {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill").foregroundStyle(
                        Color.brandYellow
                    )
                    Text(rating.average.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—")
                        .font(.headline)
                    Text(
                        String(
                            format: String(
                                localized: "listing.detail.reviewCountFormat"
                            ),
                            rating.count
                        )
                    )
                    .font(.subheadline).foregroundStyle(Color.descriptionText)
                }.foregroundStyle(Color.titleText).accessibilityElement(
                    children: .combine
                )
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.body)
                        .foregroundStyle(Color.descriptionText.opacity(0.5))

                    Text("listing.detail.reviewsUnavailable")
                        .font(.subheadline)
                        .foregroundStyle(Color.descriptionText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 6)
            }
        }
    }
}
