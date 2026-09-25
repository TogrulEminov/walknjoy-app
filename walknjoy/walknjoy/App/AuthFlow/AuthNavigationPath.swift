//
//  AuthNavigationPath.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import SwiftUI

private struct AuthNavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath> = .constant(
        NavigationPath()
    )
}

extension EnvironmentValues {
    var authNavigationPath: Binding<NavigationPath> {
        get { self[AuthNavigationPathKey.self] }
        set { self[AuthNavigationPathKey.self] = newValue }
    }
}
