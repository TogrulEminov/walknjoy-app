//
//  AppLanguage.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case az
    case en
    case ru

    var id: String {
        rawValue
    }
    var locale: Locale {
        Locale(identifier: rawValue)
    }
    var title: String {
        switch self {
        case .az:
            return "Azərbaycan dili"

        case .en: return "English"
        case .ru: return "Русский"

        }
    }
    var shortTitle: String {
        rawValue.uppercased()
    }

    var flag: String {
        switch self {
        case .az:
            return "🇦🇿"

        case .en: return "🇬🇧"
        case .ru: return "🇷🇺"

        }
    }

}
