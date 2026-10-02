import SwiftUI
 
struct StateIconView: View {
    let icon: String
    var tint: Color = .iconColor
    var background: Color = .brandYellow

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 80, height: 80)
            .background(background.opacity(0.14), in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(background.opacity(0.2), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}
