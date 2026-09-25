//
//  ErrorStateView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import SwiftUI

struct ErrorStateView: View {
    let title: LocalizedStringKey
    let message: String
    var retryTitle: LocalizedStringKey?
    var onRetry: (() -> Void)?
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.circle.fill").font(
                .system(size: 72)
            ).foregroundStyle(Color.errorColor)
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.descriptionText)
                    .multilineTextAlignment(.center)
            }
            if let retryTitle {
                Button(retryTitle) { onRetry?() }.buttonStyle(
                    .borderedProminent
                )
            }
        }.padding(.horizontal, 24)
    }
}
