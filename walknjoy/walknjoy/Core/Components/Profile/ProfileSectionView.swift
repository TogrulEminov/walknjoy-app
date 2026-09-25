//
//  ProfileSectionView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

struct ProfileSectionView: View {
    let title: LocalizedStringKey
    let items: [ProfileMenuItem]
    let onSelect: (ProfileMenuItem) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.descriptionText).padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) {
                    index,
                    item in
                    Button {
                        onSelect(item)
                    } label: {
                        ProfileRowView(item: item)
                    }.buttonStyle(.plain)
                    if index < items.count - 1 {
                        Rectangle().fill(Color.borderColor.opacity(0.6))
                            .frame(height: 0.5).padding(.leading, 64)
                    }
                }
            }
            .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.borderColor.opacity(0.6), lineWidth: 1)
            }
        }
    }
}
