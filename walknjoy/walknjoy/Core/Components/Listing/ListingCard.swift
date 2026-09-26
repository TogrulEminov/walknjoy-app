import SwiftUI

struct ListingCard: View {
    let listing: ListingResponse
    var isFavorite: Bool
    var isUpdatingFavorite = false
    let onFavoriteTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: listing.media.url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.borderColor)
                    .overlay { Image(systemName: "photo").foregroundStyle(Color.descriptionText) }
            }
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .topTrailing) {
                Button(action: onFavoriteTap) {
                    Group {
                        if isUpdatingFavorite {
                            ProgressView()
                        } else {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorite ? Color.red : Color.titleText)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.surfaceBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingFavorite)
                .accessibilityLabel(isFavorite ? "favorites.remove" : "favorites.add")
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(typeTitle).font(.caption.weight(.semibold))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Color.brandYellow.opacity(0.25), in: Capsule())
                    Spacer()
                    if let average = listing.rating.average {
                        Label("\(average) (\(listing.rating.count))", systemImage: "star.fill")
                            .font(.caption).foregroundStyle(Color.descriptionText)
                    }
                }
                Text(listing.title).font(.headline).lineLimit(2)
                if let location = listing.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline).foregroundStyle(Color.descriptionText).lineLimit(1)
                }
                if let description = listing.shortDescription, !description.isEmpty {
                    Text(description).font(.subheadline)
                        .foregroundStyle(Color.descriptionText).lineLimit(2)
                }
                Text("\(listing.basePrice) \(listing.currency)")
                    .font(.headline).padding(.top, 4)
            }
            .padding(16)
        }
        .foregroundStyle(Color.titleText)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.borderColor, lineWidth: 1) }
    }

    private var typeTitle: LocalizedStringKey {
        switch listing.type {
        case .stay: "listing.type.stay"
        case .tour: "listing.type.tour"
        case .activity: "listing.type.activity"
        case .experience: "listing.type.experience"
        }
    }
}
