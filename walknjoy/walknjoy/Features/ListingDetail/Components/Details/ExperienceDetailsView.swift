import SwiftUI

struct ExperienceDetailsView: View {
    let details: ExperienceDetails
    var body: some View {
        if details.durationMinutes != nil || details.maxParticipants != nil
            || details.minimumAge != nil || details.hostIncluded != nil
            || details.isPrivate != nil
        {
            ListingDetailSection(title: "listing.detail.experience.about") {
                ListingDetailCard {
                    ListingParticipationRows(
                        duration: details.durationMinutes,
                        maximum: details.maxParticipants,
                        minimumAge: details.minimumAge
                    )

                    if let value = details.hostIncluded {
                        ListingDetailRow(
                            title: "listing.detail.host",
                            value: String(
                                localized: value
                                    ? "listing.detail.included"
                                    : "listing.detail.notIncluded"
                            ),
                            icon: "person.crop.circle"
                        )
                    }
                    if let value = details.isPrivate {
                        ListingDetailRow(
                            title: "listing.detail.experience.type",
                            value: String(
                                localized: value
                                    ? "listing.detail.private"
                                    : "listing.detail.groupExperience"
                            ),
                            icon: "sparkles"
                        )
                    }

                }
            }
        }
    }
}
