//
//  ProfileHeaderView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 24.09.26.
//

import SwiftUI

struct ProfileHeaderView: View {
    let profile: ProfileModel
    let onEdit: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            avatarView
                .overlay {
                    Circle().stroke(
                        Color.brandYellow.opacity(0.6),
                        lineWidth: 2
                    )
                    .padding(-5)
                }
                .padding(.top, 6)

            VStack(spacing: 6) {
                Text(profile.fullName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.titleText)
                    .multilineTextAlignment(.center)

                Text(profile.email)
                    .font(.subheadline)
                    .foregroundStyle(Color.descriptionText)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)

                if let role = profile.role {
                    ProfileRoleBadge(role: role)
                        .padding(.top, 6)
                }
            }

            if let onEdit {
                Button(action: onEdit) {
                    Label(
                        "profile.editProfile",
                        systemImage: "square.and.pencil"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.buttonText)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 44)
                    .background(Color.buttonBackground, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.borderColor.opacity(0.6), lineWidth: 1)
        }
    }
}

extension ProfileHeaderView {
    private var avatarView: some View {
        AvatarImageView(file: profile.avatarFile, size: 88)
            .id(profile.avatarFile?.id)
    }
}
