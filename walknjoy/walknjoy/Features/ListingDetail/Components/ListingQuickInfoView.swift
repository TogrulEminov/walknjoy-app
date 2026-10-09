import SwiftUI

struct ListingQuickInfoView: View {
    var details: ListingDetails?
    var cardDetails: ListingCardDetails?

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 135), spacing: 12)],
            spacing: 12
        ) {
            if let details {
                switch details {
                case .stay(let value):
                    item("person.2", value.maxGuests, "listing.detail.guests")
                    item(
                        "bed.double",
                        value.bedrooms,
                        "listing.detail.bedrooms"
                    )
                    item("bed.double.fill", value.beds, "listing.detail.beds")
                    item("shower", value.bathrooms, "listing.detail.bathrooms")
                case .tour(let value):
                    participation(
                        value.durationMinutes,
                        value.maxParticipants,
                        value.minimumAge
                    )
                    if !value.languages.isEmpty {
                        item(
                            "globe",
                            value.languages.count,
                            "listing.detail.languages"
                        )
                    }
                case .activity(let value):
                    participation(
                        value.durationMinutes,
                        value.maxParticipants,
                        value.minimumAge
                    )
                    if let difficulty = value.difficulty {
                        ListingQuickInfoItem(
                            icon: "mountain.2",
                            value: ListingDetailFormatting.difficulty(
                                difficulty
                            ),
                            title: "listing.detail.difficulty"
                        )
                    }
                case .experience(let value):
                    participation(
                        value.durationMinutes,
                        value.maxParticipants,
                        value.minimumAge
                    )
                    if let host = value.hostIncluded {
                        ListingQuickInfoItem(
                            icon: "person.crop.circle",
                            value: String(
                                localized: host
                                    ? "listing.detail.included"
                                    : "listing.detail.notIncluded"
                            ),
                            title: "listing.detail.host"
                        )
                    }
                }
            } else if let cardDetails {
                switch cardDetails {
                case .stay(let value):
                    item("person.2", value?.maxGuests, "listing.detail.guests")
                case .tour(let value):
                    participation(value?.durationMinutes, nil, nil)
                case .activity(let value):
                    participation(value?.durationMinutes, nil, nil)
                case .experience: EmptyView()
                }
            }
        }
    }

    @ViewBuilder private func item(
        _ icon: String,
        _ value: Int?,
        _ title: LocalizedStringKey
    ) -> some View {
        if let value {
            ListingQuickInfoItem(
                icon: icon,
                value: value.formatted(),
                title: title
            )
        }
    }

    @ViewBuilder private func participation(
        _ duration: Int?,
        _ maximum: Int?,
        _ age: Int?
    ) -> some View {
        if let duration {
            ListingQuickInfoItem(
                icon: "clock",
                value: ListingDetailFormatting.duration(duration),
                title: "listing.detail.duration"
            )
        }
        item("person.2", maximum, "listing.detail.maxParticipants")
        if let age {
            ListingQuickInfoItem(
                icon: "figure.child",
                value: "\(age)+",
                title: "listing.detail.minimumAge"
            )
        }
    }
}
