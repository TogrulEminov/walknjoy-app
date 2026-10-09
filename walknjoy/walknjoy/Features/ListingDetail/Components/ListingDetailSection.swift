import SwiftUI

struct ListingDetailSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.titleText)
                .accessibilityAddTraits(.isHeader)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ListingDetailRow: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.brandYellow)
                .frame(width: 36, height: 36)
                .background(Color.brandYellow.opacity(0.1), in: Circle())

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    Text(title).foregroundStyle(Color.descriptionText)
                    Spacer(minLength: 8)
                    Text(value).fontWeight(.semibold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundStyle(Color.descriptionText)
                    Text(value).fontWeight(.semibold)
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(Color.titleText)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

struct ListingDetailCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.surfaceBackground,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.borderColor.opacity(0.5),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

enum ListingDetailFormatting {
    static func duration(_ minutes: Int) -> String {
        if minutes < 60 {
            return String(
                format: String(localized: "listing.detail.minutesFormat"),
                minutes
            )
        }
        if minutes % 60 == 0 {
            return String(
                format: String(localized: "listing.detail.hoursFormat"),
                minutes / 60
            )
        }
        return String(
            format: String(localized: "listing.detail.hoursMinutesFormat"),
            minutes / 60,
            minutes % 60
        )
    }

    static func location(_ location: ListingLocation) -> String {
        [location.city, location.district].compactMap { $0 }.filter {
            !$0.isEmpty
        }.joined(separator: ", ")
    }

    static func property(_ value: String) -> String {
        let normalized =
            value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: "listing.detail.property.",
                with: "",
                options: [.caseInsensitive]
            )
            .replacingOccurrences(
                of: "listing.detail.property-",
                with: "",
                options: [.caseInsensitive]
            )
            .replacingOccurrences(
                of: "listing.detail.property",
                with: "",
                options: [.caseInsensitive]
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: " .-_"))
            .lowercased()
        return switch normalized {
        case "villa": String(localized: "listing.detail.property.villa")
        case "apartment": String(localized: "listing.detail.property.apartment")
        case "house": String(localized: "listing.detail.property.house")
        case "hotel": String(localized: "listing.detail.property.hotel")
        case "cabin": String(localized: "listing.detail.property.cabin")
        default: value
        }
    }

    static func difficulty(_ value: String) -> String {
        switch value.lowercased() {
        case "easy": String(localized: "listing.detail.difficulty.easy")
        case "medium", "moderate":
            String(localized: "listing.detail.difficulty.medium")
        case "hard", "difficult":
            String(localized: "listing.detail.difficulty.hard")
        default: value
        }
    }
}
