import SwiftUI

struct TravelPlannerResultCard: View {
    let item: PlannerItem
    let isDisabled: Bool
    let onDetails: () -> Void
    let onBook: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RemoteImageView(path: item.image) {
                ZStack {
                    Color.surfaceBg
                    Image(systemName: "photo").font(.largeTitle)
                        .foregroundStyle(Color.description)
                }
            }.frame(height: 160).clipped().clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            Text(item.title).font(.headline)
            if let city = item.location?.city {
                Text(city).foregroundStyle(Color.description)
            }
            if let dates = item.dates {
                Text("\(dates.checkIn) → \(dates.checkOut)")
            }
            if let session = item.session {
                Text("\(session.startsAt) → \(session.endsAt)").font(.footnote)
            }
            Text("\(item.total) \(item.currency)").font(.title3.bold())
            Text(
                "\(item.breakdown.basePrice) × \(item.breakdown.quantity) \(item.currency)"
            ).font(.footnote)
            if item.budgetExceeded {
                Text(
                    String(localized: "planner.exceeded")
                        + " \(item.budgetDifference) \(item.currency)"
                ).foregroundStyle(.orange)
            }
            HStack {
                Button("planner.details") {
                    onDetails()
                }
                Button("planner.book") { onBook() }
            }.buttonStyle(.bordered).disabled(isDisabled)
        }.padding(14).background(
            Color.surfaceBg,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

}
