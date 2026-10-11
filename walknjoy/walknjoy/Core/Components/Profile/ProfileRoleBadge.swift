import SwiftUI

struct ProfileRoleBadge: View {
    let role: RoleEnum

    private var title: LocalizedStringKey {
        switch role {
        case .customer: "profile.role.customer"
        case .provider: "profile.role.provider"
        case .admin: "profile.role.admin"
        }
    }

    private var symbol: String {
        switch role {
        case .customer: "person.crop.circle"
        case .provider: "briefcase"
        case .admin: "shield.lefthalf.filled"
        }
    }

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.titleText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.brandYellow.opacity(0.16), in: Capsule())
            .overlay {
                Capsule().stroke(Color.brandYellow.opacity(0.4), lineWidth: 1)
            }
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProfileRoleBadge(role: .customer)
        ProfileRoleBadge(role: .provider)
        ProfileRoleBadge(role: .admin)
    }
    .padding()
    .background(Color.appBackground)
}
