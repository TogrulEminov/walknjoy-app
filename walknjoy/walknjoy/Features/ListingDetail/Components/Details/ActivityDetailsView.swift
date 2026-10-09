import SwiftUI

struct ActivityDetailsView: View {
    let details: ActivityDetails
    var body: some View {
        if details.durationMinutes != nil || details.maxParticipants != nil
            || details.minimumAge != nil || details.difficulty != nil
            || details.equipmentProvided != nil
        {
            ListingDetailSection(title: "listing.detail.activity.about") {
                ListingDetailCard {
                    ListingParticipationRows(
                        duration: details.durationMinutes,
                        maximum: details.maxParticipants,
                        minimumAge: details.minimumAge
                    )

                    if let value = details.difficulty {
                        ListingDetailRow(
                            title: "listing.detail.difficulty",
                            value: ListingDetailFormatting.difficulty(value),
                            icon: "mountain.2"
                        )
                    }
                    if let value = details.equipmentProvided {
                        ListingDetailRow(
                            title: "listing.detail.equipment",
                            value: String(
                                localized: value
                                    ? "listing.detail.provided"
                                    : "listing.detail.notProvided"
                            ),
                            icon: "backpack"
                        )
                    }

                }
            }
        }
    }
}
