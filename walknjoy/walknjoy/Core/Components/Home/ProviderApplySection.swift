//
//  ProviderApplySection.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 02.10.26.
//

import SwiftUI

struct ProviderApplySection: View {
    @State private var showingApplication = false

    var body: some View {
        Button {
            showingApplication = true
        } label: {
            ZStack(alignment: .leading) {
                providerImage
                content
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingApplication) {
            NavigationStack {
                ProviderApplicationView()
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.appBackground)
        }
    }
}

// MARK: - Content

extension ProviderApplySection {

    fileprivate var content: some View {
        VStack(alignment: .leading, spacing: 8) {

            badge

            Text("home.provider.title")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Text("home.provider.description")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            applyButton
        }
        .padding(.vertical,10)
        .padding(.horizontal,15)
        .frame(
            maxWidth: 245,
            alignment: .leading
        )
    }

    fileprivate var badge: some View {
        Text("home.provider.badge")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(
                Color(uiColor: AppColors.buttonText)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.brandYellow)
            .clipShape(Capsule())
    }

    fileprivate var applyButton: some View {
        HStack(spacing: 10) {

            Text("home.provider.button")
                .font(.system(size: 12, weight: .semibold))

            Image(systemName: "arrow.right")
                .font(
                    .system(
                        size: 10,
                        weight: .semibold
                    )
                )
        }
        .foregroundStyle(
            Color(uiColor: AppColors.buttonText)
        )
        .padding(.horizontal, 13)
        .frame(height: 38)
        .background(Color.brandYellow)
        .clipShape(Capsule())
    }
}

// MARK: - Background Image

extension ProviderApplySection {

    fileprivate var providerImage: some View {
        GeometryReader { proxy in
            Image("provider-banner")
                .resizable()
                .scaledToFill()
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                .clipped()
        }
    }
}
