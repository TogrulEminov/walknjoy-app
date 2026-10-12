//
//  OnboardingPageView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let currentPage: Int
    let totalPages: Int
    let isLastPage: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundImage
                .ignoresSafeArea()

            gradientOverlay
                .ignoresSafeArea()

            skipButton
            bottomCard
        }
    }
}
extension OnboardingPageView {
    private var backgroundImage: some View {
        Image(page.imageName)
            .resizable().scaledToFill().frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            ).clipped()
    }
}
extension OnboardingPageView {
    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.black.opacity(0.05),
                Color.black.opacity(0.30),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
extension OnboardingPageView {
    private var skipButton: some View {

        VStack {
            HStack {
                Spacer()

                Button(action: onSkip) {
                    Text("onboarding.skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Color.black.opacity(0.20)
                        )
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)

    }
}
extension OnboardingPageView {
    private func pageIcon(_ icon: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.surfaceBackground)
                .frame(width: 72, height: 72)

            Circle()
                .fill(Color.brandYellow.opacity(0.15))
                .frame(width: 64, height: 64)

            Image(systemName: icon)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(Color.brandYellow)
        }
    }
}
extension OnboardingPageView {
    private var bottomCard: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Text(page.title)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color.titleText)
                        .multilineTextAlignment(.center)

                    Text(page.description)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.titleText.opacity(0.70))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }

                Spacer()
                    .frame(height: 26)

                bottomControls
            }
            .padding(.horizontal, 25)
            .padding(.top, page.icon == nil ? 26 : 46)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
            .background(Color.surfaceBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    topTrailingRadius: 28
                )
            )

            if let icon = page.icon {
                pageIcon(icon)
                    .offset(y: -32)
            }
        }
    }
}
extension OnboardingPageView {

    private var bottomControls: some View {
        HStack {

            PageIndicator(
                currentPage: currentPage,
                totalPages: totalPages
            )

            Spacer()

            Button(action: onNext) {
                Group {
                    if isLastPage {

                        Text("onboarding.start")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .padding(.horizontal, 22)

                    } else {

                        Image(systemName: "arrow.right")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )
                    }
                }
                .foregroundStyle(Color.buttonText)
                .frame(minWidth: 52)
                .frame(height: 52)
                .background(Color.buttonBackground)
                .clipShape(Capsule())

            }
        }
    }
}
