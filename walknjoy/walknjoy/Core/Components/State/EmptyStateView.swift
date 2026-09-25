//
//  EmptyStateView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import SwiftUI

struct EmptyStateView: View {

    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 16) {

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.iconColor)

            Text(title)
                .font(.system(size: 20, weight: .semibold))

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.descriptionText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}
