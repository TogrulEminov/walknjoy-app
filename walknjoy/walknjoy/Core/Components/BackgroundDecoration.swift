//
//  BackgroundDecoration.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 18.09.26.
//

import SwiftUI

struct BackgroundDecoration: View {

    @Environment(\.colorScheme)
    private var colorScheme

    private var decorationColor: Color {
        colorScheme == .dark
            ? .white
            : .secondary
    }

    private var circleOpacity: Double {
        colorScheme == .dark ? 0.12 : 0.08
    }

    private var iconOpacity: Double {
        colorScheme == .dark ? 0.10 : 0.06
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        Color.primaryYellow.opacity(circleOpacity)
                    )
                    .frame(width: 230, height: 230)
                    .position(
                        x: geo.size.width - 30,
                        y: 90
                    )

                Image(systemName: "airplane")
                    .font(
                        .system(size: 38, weight: .medium)
                    )
                    .foregroundStyle(
                        decorationColor.opacity(iconOpacity)
                    )
                    .rotationEffect(.degrees(-25))
                    .position(
                        x: geo.size.width - 70,
                        y: 150
                    )

                Image(systemName: "map.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        decorationColor.opacity(iconOpacity)
                    )
                    .rotationEffect(.degrees(-25))
                    .position(
                        x: geo.size.width - 150,
                        y: 250
                    )

                Image(systemName: "cloud.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        decorationColor.opacity(
                            colorScheme == .dark ? 0.08 : 0.045
                        )
                    )
                    .position(
                        x: geo.size.width - 65,
                        y: 315
                    )

                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(
                        decorationColor.opacity(
                            colorScheme == .dark ? 0.07 : 0.04
                        )
                    )
                    .position(
                        x: geo.size.width - 80,
                        y: 400
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#Preview("Light Mode") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        BackgroundDecoration()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        BackgroundDecoration()
    }
    .preferredColorScheme(.dark)
}
