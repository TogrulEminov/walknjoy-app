//
//  LoginBackgroundDecoration.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 18.09.26.
//

import SwiftUI

struct LoginBackgroundDecoration: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(.primaryYellow.opacity(0.08)).frame(
                    width: 230,
                    height: 230
                ).position(x: geo.size.width - 30, y: 90)

                Image(systemName: "airplane")
                    .font(
                        .system(size: 38, weight: .medium)
                    )
                    .foregroundStyle(.primaryBlue.opacity(0.08))
                    .rotationEffect(
                        .degrees(-25)
                    )
                    .position(x: geo.size.width - 70, y: 150)

                Image(systemName: "map.circle.fill")
                    .font(
                        .system(size: 34)
                    )
                    .foregroundStyle(.primaryBlue.opacity(0.07))
                    .rotationEffect(
                        .degrees(-25)
                    )
                    .position(x: geo.size.width - 150, y: 250)

                Image(systemName: "cloud.fill")
                    .font(
                        .system(size: 48)
                    )
                    .foregroundStyle(.primaryBlue.opacity(0.045))
                    .position(x: geo.size.width - 65, y: 315)

                Image(systemName: "mountain.2.fill")
                    .font(
                        .system(size: 90)
                    )
                    .foregroundStyle(.primaryBlue.opacity(0.04))
                    .position(x: geo.size.width - 80, y: 400)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

#Preview {
    LoginBackgroundDecoration()
}
