import SwiftUI
import UIKit

struct ListingDescriptionView: View {
    private let formattedDescription: AttributedString
    @State private var expanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0

    init(description: String) {
        formattedDescription = ListingDescriptionFormatter.format(description)
    }

    var body: some View {
        ListingDetailSection(title: "listing.detail.about") {
            Text(formattedDescription)
                .font(.subheadline).foregroundStyle(Color.descriptionText)
                .lineSpacing(3).lineLimit(expanded ? nil : 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    measuredText(lineLimit: nil) { fullHeight = $0 }
                    measuredText(lineLimit: 4) { collapsedHeight = $0 }
                }
            if fullHeight > collapsedHeight + 1 {
                Button(
                    expanded
                        ? "listing.detail.showLess" : "listing.detail.showMore"
                ) {
                    expanded.toggle()
                }
                .font(.subheadline.weight(.semibold)).tint(Color.titleText)
                .frame(minHeight: 44)
            }
        }
    }

    private func measuredText(
        lineLimit: Int?,
        onMeasure: @escaping (CGFloat) -> Void
    ) -> some View {
        Text(formattedDescription)
            .font(.subheadline).lineSpacing(3).lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) {
                $0.size.height
            } action: {
                onMeasure($0)
            }
            .hidden()
            .accessibilityHidden(true)
    }
}


@MainActor
enum ListingDescriptionFormatter {
    static func format(_ source: String) -> AttributedString {
        if source.range(of: "<\\s*(p|h[1-6]|ul|ol|li|div|br|strong|em|blockquote)(?:\\s|>|/)", options: .regularExpression) != nil,
            let data = source.data(using: .utf8),
            let html = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            ) {
            var result = AttributedString()
            html.enumerateAttributes(in: NSRange(location: 0, length: html.length)) { attributes, range, _ in
                var part = AttributedString((html.string as NSString).substring(with: range))
                if let font = attributes[.font] as? UIFont {
                    let traits = font.fontDescriptor.symbolicTraits
                    var displayFont = Font.system(size: font.pointSize > 14 ? font.pointSize : 15)
                    if traits.contains(.traitBold) { displayFont = displayFont.bold() }
                    if traits.contains(.traitItalic) { displayFont = displayFont.italic() }
                    part.font = displayFont
                }
                if let link = attributes[.link] as? URL { part.link = link }
                if attributes[.underlineStyle] != nil { part.underlineStyle = .single }
                result.append(part)
            }
            return result
        }

        var result = AttributedString()
        let lines = source.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            var text = line
            var headingLevel: Int?
            if let range = text.range(of: "^#{1,6}\\s+", options: .regularExpression) {
                headingLevel = text[range].filter { $0 == "#" }.count
                text.removeSubrange(range)
            } else if let range = text.range(of: "^\\s*[-*+]\\s+", options: .regularExpression) {
                text.replaceSubrange(range, with: "• ")
            }
            var part = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
            if let headingLevel {
                part.font = .system(size: headingLevel == 1 ? 24 : headingLevel == 2 ? 20 : 17, weight: .semibold)
            }
            result.append(part)
            if index < lines.count - 1 { result.append(AttributedString("\n")) }
        }
        return result
    }
}
