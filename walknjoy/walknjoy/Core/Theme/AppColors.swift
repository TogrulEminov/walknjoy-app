import UIKit

enum AppColors {
    private static func color(named name: String, fallback: UIColor) -> UIColor
    {
        UIColor(named: name) ?? fallback
    }

    static let appBackground = color(
        named: "appBackground",
        fallback: .systemBackground
    )
    static let surfaceBackground = color(
        named: "surfaceBackground",
        fallback: .secondarySystemBackground
    )
    static let borderColor = color(named: "borderColor", fallback: .separator)
    static let titleText = color(named: "titleText", fallback: .label)
    static let descriptionText = color(
        named: "descriptionText",
        fallback: .secondaryLabel
    )
    static let placeholderText = color(
        named: "placeholderText",
        fallback: .placeholderText
    )
    static let iconColor = color(named: "iconColor", fallback: .secondaryLabel)
    static let buttonBackground = color(
        named: "buttonBackground",
        fallback: .systemBlue
    )
    static let buttonText = color(named: "buttonText", fallback: .white)
    static let brandYellow = color(
        named: "brandYellow",
        fallback: .systemYellow
    )
    static let disabledBackground = color(
        named: "disabledBackground",
        fallback: .tertiarySystemBackground
    )
    static let errorColor = color(named: "errorColor", fallback: .systemRed)
}
