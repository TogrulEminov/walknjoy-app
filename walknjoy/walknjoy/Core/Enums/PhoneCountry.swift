//
//  PhoneCountry.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 25.09.26.
//

import Foundation

enum PhoneCountry: String, CaseIterable, Identifiable {

    case azerbaijan
    case turkey
    case georgia
    case russia

    var id: Self { self }

    var title: String {
        switch self {
        case .azerbaijan:
            "🇦🇿 Azərbaycan"

        case .turkey:
            "🇹🇷 Türkiyə"

        case .georgia:
            "🇬🇪 Gürcüstan"

        case .russia:
            "🇷🇺 Rusiya"
        }
    }

    var dialCode: String {
        switch self {
        case .azerbaijan:
            "+994"

        case .turkey:
            "+90"

        case .georgia:
            "+995"

        case .russia:
            "+7"
        }
    }

    var groups: [Int] {
        switch self {
        case .azerbaijan:
            [2, 3, 2, 2] // 50 123 45 67

        case .turkey:
            [3, 3, 2, 2] // 5xx xxx xx xx

        case .georgia:
            [3, 2, 2, 2] // 5xx xx xx xx

        case .russia:
            [3, 3, 2, 2] // 9xx xxx xx xx
        }
    }

    var digitCount: Int {
        groups.reduce(0, +)
    }
}

// MARK: - Phone Helpers

extension PhoneCountry {

    static func detect(
        from phone: String?
    ) -> PhoneCountry {

        guard let phone,
              !phone.isEmpty else {
            return .azerbaijan
        }

        let normalized = phone
            .replacingOccurrences(
                of: " ",
                with: ""
            )

        return allCases.first {
            normalized.hasPrefix(
                $0.dialCode
            )
        } ?? .azerbaijan
    }

    func localNumber(
        from phone: String?
    ) -> String {

        guard let phone,
              !phone.isEmpty else {
            return ""
        }

        let digits = phone.filter(\.isNumber)

        let countryDigits =
            dialCode.filter(\.isNumber)

        if digits.hasPrefix(countryDigits) {
            return String(
                digits
                    .dropFirst(
                        countryDigits.count
                    )
                    .prefix(digitCount)
            )
        }

        return String(
            digits.prefix(digitCount)
        )
    }

    func fullNumber(
        from localNumber: String
    ) -> String {

        let digits = localNumber.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        return dialCode + String(digits.prefix(digitCount))
    }
}
