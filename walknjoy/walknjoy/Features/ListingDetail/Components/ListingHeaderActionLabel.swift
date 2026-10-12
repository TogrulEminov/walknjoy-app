import SwiftUI

struct ListingHeaderActionLabel: View {
    let symbol: String
    var tint: Color = .titleText
    var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(tint)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .foregroundStyle(tint)
        .frame(width: 44, height: 44)
        .background(Color.surfaceBackground, in: Circle())
        .overlay {
            Circle().strokeBorder(
                Color.borderColor.opacity(0.5),
                lineWidth: 0.5
            )
        }
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .contentShape(Circle())
    }
}
