//
//  HomeListingTypeItem.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import SwiftUI

struct HomeListingTypeItem: View {

    let type: ListingType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.surfaceBg)
                        .frame(width: 64, height: 64)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.border.opacity(0.7), lineWidth: 1)
                        }

                    Image(systemName: type.icon)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(Color.icon)
                }

                Text(type.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.title)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
