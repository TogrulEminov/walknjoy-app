import SwiftUI

struct StayDetailsView: View {
    let details: StayDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ListingDetailSection(title: "listing.detail.stay.about") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        DetailFeatureItem(icon: "house", title: "listing.detail.propertyType", value: ListingDetailFormatting.property(details.propertyType))
                            .frame(width: 124)
                        DetailFeatureItem(icon: "person.2", title: "listing.detail.guests", value: details.maxGuests.formatted())
                            .frame(width: 124)
                        if let bedrooms = details.bedrooms {
                            DetailFeatureItem(icon: "bed.double", title: "listing.detail.bedrooms", value: bedrooms.formatted())
                                .frame(width: 124)
                        }
                        if let beds = details.beds {
                            DetailFeatureItem(icon: "bed.double.fill", title: "listing.detail.beds", value: beds.formatted())
                                .frame(width: 124)
                        }
                        if let bathrooms = details.bathrooms {
                            DetailFeatureItem(icon: "shower", title: "listing.detail.bathrooms", value: bathrooms.formatted())
                                .frame(width: 124)
                        }
                    }
                }
            }
            if hasRules {
                ListingDetailSection(title: "listing.detail.stay.rules") {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: rule.icon)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.brandYellow)
                                    .frame(width: 34, height: 34)
                                    .background(Color.brandYellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(rule.title)
                                        .font(.caption).foregroundStyle(Color.descriptionText)
                                    Text(rule.value)
                                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.titleText)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 13)
                            .accessibilityElement(children: .combine)
                            if index < rules.count - 1 {
                                Divider().overlay(Color.borderColor.opacity(0.5)).padding(.leading, 46)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor.opacity(0.5), lineWidth: 1))
                }
            }
        }
    }

    private var hasRules: Bool { !rules.isEmpty }

    private var rules: [(title: LocalizedStringKey, value: String, icon: String)] {
        var rows: [(title: LocalizedStringKey, value: String, icon: String)] = []
        if let value = timeRange(details.checkInFrom, details.checkInUntil) {
            rows.append(("listing.detail.checkIn", value, "arrow.right.to.line"))
        }
        if let value = timeRange(details.checkOutFrom, details.checkOutUntil) {
            rows.append(("listing.detail.checkOut", value, "arrow.left.to.line"))
        }
        if let nights = details.minimumNights {
            rows.append(("listing.detail.minimumNights", String(format: String(localized: "listing.detail.nightsFormat"), nights), "moon"))
        }
        if let instant = details.instantBooking {
            rows.append(("listing.detail.instantBooking", String(localized: instant ? "listing.detail.available" : "listing.detail.onRequest"), "bolt"))
        }
        return rows
    }

    private func timeRange(_ from: String?, _ until: String?) -> String? {
        switch (from, until) {
        case (.some(let start), .some(let end)): "\(start) – \(end)"
        case (.some(let start), nil): String(format: String(localized: "listing.detail.fromTimeFormat"), start)
        case (nil, .some(let end)): String(format: String(localized: "listing.detail.untilTimeFormat"), end)
        case (nil, nil): nil
        }
    }
}

struct DetailFeatureItem: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.brandYellow)
                .frame(width: 36, height: 36)
                .background(Color.brandYellow.opacity(0.1), in: Circle())

            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.titleText)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.descriptionText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.appBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
