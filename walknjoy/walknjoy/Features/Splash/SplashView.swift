//
//  SplashView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("splash_background")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.75),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Image("logo-white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .padding(.top, 70)

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("onboarding.story.title")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("onboarding.story.description")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                    .frame(height: 55)
            }
            .padding(.horizontal, 24)
        }
    }
}
#Preview {
    SplashView()
}
