//
//  SuccessStateView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import SwiftUI

struct SuccessStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var buttonTitle: LocalizedStringKey?
    var onButtonTap: (() -> Void)?
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 72))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(message).font(.system(size: 15)).foregroundStyle(
                    .secondary
                ).multilineTextAlignment(.center).lineSpacing(4)
            }
            if let buttonTitle {
                Button {
                    onButtonTap?()
                } label: {
                    Text(buttonTitle).font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary).frame(
                            maxWidth: .infinity
                        ).frame(height: 56).background(Color.primaryYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)

            }
        }
    }
}
