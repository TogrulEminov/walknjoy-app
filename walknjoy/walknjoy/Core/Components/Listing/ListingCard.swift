import SwiftUI

struct ListingCard: View {
    let listing: PublicListing
    var isFavorite: Bool
    var isUpdatingFavorite = false
    var canFavorite = false
    let onFavoriteTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: AppRoute.listingDetails(listing)) {
                VStack(alignment: .leading, spacing: 0) {
                    RemoteImageView(url: imageURL) { placeholder }
                        .frame(height: 168)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(listing.type.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color.brandY.opacity(0.28),
                                    in: Capsule()
                                )
                            Spacer()
                            if let average = listing.rating.average {
                                Label(
                                    average.formatted(
                                        .number.precision(.fractionLength(1))
                                    ),
                                    systemImage: "star.fill"
                                )
                                .font(.caption)
                                .foregroundStyle(Color.description)
                            }
                        }

                        Text(listing.title)
                            .font(.headline)
                            .lineLimit(2, reservesSpace: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let location = listing.location {
                            Label {
                                Text(
                                    verbatim:
                                        "\(location.city ?? ""), \(location.countryCode)"
                                )
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                            }
                            .font(.subheadline).foregroundStyle(
                                Color.description
                            ).lineLimit(1)
                        }

                        HStack {
                            if let category = listing.category {
                                Text(category.name).lineLimit(1)
                            }
                            if let detailText {
                                Spacer()
                                Text(detailText)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.description)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formattedPrice).font(.headline)
                            Text(listing.currency).font(.subheadline)
                            Spacer()
                            if listing.rating.count > 0 {
                                Text(verbatim: "(\(listing.rating.count))")
                                    .font(.caption).foregroundStyle(
                                        Color.description
                                    )
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .buttonStyle(.plain)

            if canFavorite {
                favoriteButton
                    .padding(10)
                    .zIndex(1)
            }
        }
        .foregroundStyle(Color.title)
        .background(Color.surfaceBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.border, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteTap) {
            Group {
                if isUpdatingFavorite {
                    ProgressView()
                } else {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                }
            }
            .foregroundStyle(isFavorite ? Color.errorC : Color.title)
            .frame(width: 44, height: 44)
            .background(Color.surfaceBg.opacity(0.92), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingFavorite)
        .accessibilityLabel(isFavorite ? "favorites.remove" : "favorites.add")
    }

    private var placeholder: some View {
        Color.border.overlay {
            Image(systemName: "photo").foregroundStyle(Color.description)
        }
    }

    private var imageURL: URL? {
        guard listing.coverMedia?.type == .image,
            let value = listing.coverMedia?.url
        else { return nil }
        return URL(string: value)
    }

    private var formattedPrice: String {
        return listing.basePrice.formatted(
            .number.precision(.fractionLength(0...2))
        )
    }

    private var detailText: String? {
        switch listing.details {
        case .stay(let details):
            return details.map {
                String(
                    format: String(localized: "listing.guests.summaryFormat"),
                    $0.maxGuests
                )
            }
        case .tour(let details): return details?.durationMinutes.map(duration)
        case .activity(let details):
            return details?.durationMinutes.map(duration)
        case .experience: return nil
        }
    }

    private func duration(_ minutes: Int) -> String {
        minutes >= 60
            ? String(
                format: String(localized: "listing.duration.hoursFormat"),
                minutes / 60
            )
            : String(
                format: String(
                    localized: "listing.duration.shortMinutesFormat"
                ),
                minutes
            )
    }
}
