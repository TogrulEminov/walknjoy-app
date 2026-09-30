//
//  AITravelBannerView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import SwiftUI

struct AITravelBannerView: View {

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            content
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 190)
            .background { background }
            .clipShape(bannerShape)
            .overlay {
                bannerShape
                    .stroke(Color.border.opacity(0.7), lineWidth: 1)
            }
            .contentShape(bannerShape)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var bannerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }
}

// MARK: - Background

extension AITravelBannerView {

    fileprivate var background: some View {
        GeometryReader { geometry in
            Image("ai-travel-banner")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [Color.brandInk.opacity(0.96), Color.brandInk.opacity(0.88), Color.brandInk.opacity(0.72)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
        }
    }
}

// MARK: - Content

extension AITravelBannerView {

    fileprivate var content: some View {
        HStack(spacing: 0) {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                title

                description

                planButton
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    fileprivate var title: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(
                    .system(
                        size: 20,
                        weight: .bold
                    )
                )
                .foregroundStyle(Color.brandY)

            Text("home.ai.brand")
                .font(
                    .system(
                        size: 21,
                        weight: .bold
                    )
                )
                .foregroundStyle(Color.brandY)

            Text("home.ai.new")
                .font(
                    .system(
                        size: 10,
                        weight: .bold
                    )
                )
                .foregroundStyle(Color.brandInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.brandY)
                .clipShape(Capsule())
        }
    }

    fileprivate var description: some View {
        Text("home.ai.description")
            .font(
                .system(
                    size: 15,
                    weight: .medium
                )
            )
            .foregroundStyle(.white)
            .lineSpacing(2)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
    }

    fileprivate var planButton: some View {
        HStack(spacing: 12) {
            Text("home.ai.button")
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )

            Image(systemName: "arrow.right")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
        }
        .foregroundStyle(Color.brandInk)
        .padding(.horizontal, 20)
        .frame(height: 44)
        .background(Color.brandY)
        .clipShape(Capsule())
    }
}
