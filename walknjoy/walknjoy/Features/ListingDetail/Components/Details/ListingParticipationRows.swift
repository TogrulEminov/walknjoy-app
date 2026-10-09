import SwiftUI

struct ListingParticipationRows: View {
    let duration: Int?
    let maximum: Int?
    let minimumAge: Int?
    var body: some View {
        if let duration {
            ListingDetailRow(
                title: "listing.detail.duration",
                value: ListingDetailFormatting.duration(duration),
                icon: "clock"
            )
        }
        if let maximum {
            ListingDetailRow(
                title: "listing.detail.maxParticipants",
                value: maximum.formatted(),
                icon: "person.2"
            )
        }
        if let minimumAge {
            ListingDetailRow(
                title: "listing.detail.minimumAge",
                value: "\(minimumAge)+",
                icon: "figure.child"
            )
        }
    }
}
