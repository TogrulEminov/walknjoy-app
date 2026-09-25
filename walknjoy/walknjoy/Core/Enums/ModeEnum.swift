//
//  ModeEnum.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//
import Foundation
import SwiftUI

enum Mode: String, CaseIterable, Equatable {
    case system
    case dark
    case light
}

extension Mode {
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light

        case .dark:
            return .dark

        case .system:
            return nil
        }
    }
}
