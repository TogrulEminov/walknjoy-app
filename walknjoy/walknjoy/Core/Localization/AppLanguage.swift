//
//  AppLanguage.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case az

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

        }
    }
    var shortTitle: String {
        rawValue.uppercased()
    }

    var flag: String {
        switch self {
        case .az:
            return "🇦🇿"

        }
    }

}
