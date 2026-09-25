//
//  ProfileRowView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

struct ProfileRowView: View {
    let item: ProfileMenuItem
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.iconColor)
                .frame(width: 34, height: 34)
                .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 10))
            Text(LocalizedStringKey(item.title))
                .font(.body.weight(.medium))
                .foregroundStyle(Color.titleText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(
                    .system(size: 13, weight: .semibold)
                )
                .foregroundStyle(Color.iconColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}
