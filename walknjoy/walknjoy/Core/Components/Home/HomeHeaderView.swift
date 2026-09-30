//
//  HomeHeaderView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import SwiftUI

struct HomeHeaderView: View {
    var onImage = false
    var unreadCount = 0
    let onNotificationTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            LogoView(usesWhiteLogo: onImage)
            Spacer()
            notificationButton
        }
        .padding(.horizontal, 20)
    }
}
extension HomeHeaderView {
    var notificationButton: some View {

        Button(action: onNotificationTap) {
            ZStack {
                Circle()
                    .fill(onImage ? Color.brandInk.opacity(0.20) : Color.surfaceBg)
                    .frame(width: 44, height: 44)

                Circle()
                    .stroke(
                        onImage ? Color.brandYellow.opacity(0.35) : Color.border,
                        lineWidth: 1
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "bell")
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(onImage ? Color.brandYellow : Color.icon)
            }
        }
        .overlay(alignment: .topTrailing) {
            if unreadCount > 0 {
                Text(unreadCount > 99 ? "99+" : String(unreadCount))
                    .font(.caption2.bold())
                    .foregroundStyle(Color.brandInk)
                    .padding(.horizontal, 5)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.brandY, in: Capsule())
                    .offset(x: 5, y: -4)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(Text(String(format: String(localized: "notifications.unreadCountFormat"), unreadCount)))
        .accessibilityLabel(
            Text("home.notifications")
        )

    }
}
