//
//  ProfileStatsView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import SwiftUI

struct ProfileStatsView: View {
    let stats: ProfileStats

    var body: some View {
        HStack {
            statItem(value: stats.bookings, title: "profile.bookings")
            divider
            statItem(value: stats.favorites, title: "profile.favorites")
            divider
            statItem(value: stats.reviews, title: "profile.reviews")
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderColor.opacity(0.6), lineWidth: 1)
        }
    }
}
extension ProfileStatsView {
    private func statItem(
        value: Int,
        title: LocalizedStringKey
    ) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: "\(value)")
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.titleText)

            Text(title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.descriptionText)
        }
        .frame(maxWidth: .infinity)
    }

}
extension ProfileStatsView {

    private var divider: some View {
        Rectangle()
            .fill(Color.borderColor)
            .frame(width: 1, height: 36)
    }
}
