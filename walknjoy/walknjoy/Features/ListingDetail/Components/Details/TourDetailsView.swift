import SwiftUI

struct TourDetailsView: View {
    let details: TourDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if details.durationMinutes != nil || details.maxParticipants != nil
                || details.minimumAge != nil || !details.languages.isEmpty
                || details.isPrivateTour != nil
            {
                ListingDetailSection(title: "listing.detail.tour.about") {
                    ListingDetailCard {
                        ListingParticipationRows(
                            duration: details.durationMinutes,
                            maximum: details.maxParticipants,
                            minimumAge: details.minimumAge
                        )
                        if !details.languages.isEmpty {
                            ListingDetailRow(
                                title: "listing.detail.languages",
                                value: details.languages.map { $0.uppercased() }
                                    .joined(separator: " • "),
                                icon: "globe"
                            )
                        }
                        if let value = details.isPrivateTour {
                            ListingDetailRow(
                                title: "listing.detail.tour.type",
                                value: String(
                                    localized: value
                                        ? "listing.detail.private"
                                        : "listing.detail.groupTour"
                                ),
                                icon: "person.2"
                            )
                        }
                    }
                }
            }
            if let point = details.meetingPoint, !point.isEmpty {
                ListingDetailSection(title: "listing.detail.meetingPoint") {
                    Label(point, systemImage: "mappin.and.ellipse").font(
                        .subheadline
                    ).foregroundStyle(Color.descriptionText)
                }
            }
        }
    }
}
