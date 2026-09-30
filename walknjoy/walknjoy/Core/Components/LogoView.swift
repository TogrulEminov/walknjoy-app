//
//  LogoComponent.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import SwiftUI

struct LogoView: View {
    var usesWhiteLogo = false

    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        Image(
            usesWhiteLogo || colorScheme == .dark
                ? "logo-white"
                : "logo-colorfull"
        )
        .resizable()
        .scaledToFit()
        .frame(width: 150)
    }
}
