import SwiftUI

struct BackgroundDecoration: View {

    @Environment(\.colorScheme)
    private var colorScheme

    private var decorationColor: Color {
        Color.iconColor
    }

    private var circleOpacity: Double {
        colorScheme == .dark ? 0.045 : 0.08
    }

    private var iconOpacity: Double {
        colorScheme == .dark ? 0.14 : 0.06
    }

    private var cloudOpacity: Double {
        colorScheme == .dark ? 0.10 : 0.045
    }

    private var mountainOpacity: Double {
        colorScheme == .dark ? 0.09 : 0.04
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        Color.brandYellow.opacity(circleOpacity)
                    )
                    .frame(width: 230, height: 230)
                    .position(
                        x: geo.size.width - 30,
                        y: 90
                    )

                Image(systemName: "airplane")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(
                        decorationColor.opacity(iconOpacity)
                    )
                    .rotationEffect(.degrees(-25))
                    .position(
                        x: geo.size.width - 70,
                        y: 150
                    )

                Image(systemName: "map.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        decorationColor.opacity(iconOpacity)
                    )
                    .rotationEffect(.degrees(-25))
                    .position(
                        x: geo.size.width - 150,
                        y: 250
                    )

                Image(systemName: "cloud.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        decorationColor.opacity(cloudOpacity)
                    )
                    .position(
                        x: geo.size.width - 65,
                        y: 315
                    )

                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(
                        decorationColor.opacity(mountainOpacity)
                    )
                    .position(
                        x: geo.size.width - 80,
                        y: 400
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Light Mode") {
    ZStack {
        Color.appBackground
            .ignoresSafeArea()

        BackgroundDecoration()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        Color.appBackground
            .ignoresSafeArea()

        BackgroundDecoration()
    }
    .preferredColorScheme(.dark)
}
