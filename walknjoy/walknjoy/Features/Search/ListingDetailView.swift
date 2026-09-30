import SwiftUI

struct ListingDetailView: View {
    let data: PublicListing

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AsyncImage(url: data.coverMedia.flatMap { URL(string: $0.url) }) { phase in
                    if case .success(let image) = phase { image.resizable().scaledToFill() }
                    else { Color.border.overlay { Image(systemName: "photo") } }
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    Text(data.title).font(.title.bold())
                    if let description = data.shortDescription {
                        Text(description).foregroundStyle(Color.description)
                    }
                    if let location = data.location {
                        Label {
                            Text(verbatim: "\(location.city ?? ""), \(location.countryCode)")
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                    }
                    Text(verbatim: "\(NSDecimalNumber(decimal: data.basePrice).stringValue) \(data.currency)")
                        .font(.title2.bold())
                    if data.rating.count > 0, let rating = data.rating.average {
                        Label(
                            "\(rating.formatted(.number.precision(.fractionLength(1)))) (\(data.rating.count))",
                            systemImage: "star.fill"
                        )
                    }
                    if let summary = detailSummary {
                        Text(summary).foregroundStyle(Color.description)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.appBg)
        .navigationTitle(data.category?.name ?? data.type.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("listing-detail-\(data.slug)")
    }

    private var detailSummary: String? {
        switch data.details {
        case .stay(let details):
            details.map {
                String(format: String(localized: "listing.guests.summaryFormat"), $0.maxGuests)
            }
        case .tour(let details):
            details?.durationMinutes.map(duration)
        case .activity(let details):
            details?.durationMinutes.map(duration)
        case .experience:
            nil
        }
    }

    private func duration(_ minutes: Int) -> String {
        minutes >= 60
            ? String(format: String(localized: "listing.duration.hoursFormat"), minutes / 60)
            : String(format: String(localized: "listing.duration.shortMinutesFormat"), minutes)
    }
}
