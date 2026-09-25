//
//  AuthHeader.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 22.09.26.
//

import SwiftUI

struct AuthHeader: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.titleText)
            Text(description).font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.titleText.opacity(0.45)).lineSpacing(3)
        }

    }
}
