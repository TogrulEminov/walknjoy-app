import SwiftUI

struct HomeHeroView<SearchContent: View>: View {
    var topInset: CGFloat = 0
    var unreadCount = 0
    let onNotificationTap: () -> Void
    @ViewBuilder let searchContent: () -> SearchContent

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HomeHeaderView(onImage: true, unreadCount: unreadCount, onNotificationTap: onNotificationTap)

            VStack(alignment: .leading, spacing: 12) {
                Capsule()
                    .fill(Color.brandYellow)
                    .frame(width: 36, height: 4)
                    .accessibilityHidden(true)

                Text("home.hero.title")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("home.hero.description")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 440, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 12)

            searchContent()
        }
        .padding(.top, topInset + 16)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { geometry in
                Image("hero-banner")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: Color.brandInk.opacity(0.50), location: 0),
                                .init(color: Color.brandInk.opacity(0.30), location: 0.3),
                                .init(color: Color.brandInk.opacity(0.70), location: 0.65),
                                .init(color: Color.brandInk.opacity(0.94), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .accessibilityHidden(true)
            }
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }
}
