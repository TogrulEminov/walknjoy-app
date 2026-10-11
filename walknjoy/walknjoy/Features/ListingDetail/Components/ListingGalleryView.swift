import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ListingGalleryView: View {
    let imagePaths: [String]
    var height: CGFloat = 230
    var bottomInset: CGFloat = 0
    @State private var selection = 0

    var body: some View {
        ZStack {
            if imagePaths.isEmpty {
                placeholder
            } else {
                TabView(selection: $selection) {
                    ForEach(Array(imagePaths.enumerated()), id: \.offset) { index, path in
                        GeometryReader { geometry in
                            RemoteImageView(path: path) { placeholder }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            LinearGradient(
                colors: [.black.opacity(0.2), .clear, .black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            VStack {
                Spacer()
                if !imagePaths.isEmpty {
                    HStack {
                        Spacer()
                        Text(verbatim: "\(min(selection + 1, imagePaths.count)) / \(imagePaths.count)")
                            .font(.caption.weight(.semibold)).monospacedDigit()
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .foregroundStyle(.white)
                            .background(.black.opacity(0.45), in: Capsule())
                            .accessibilityLabel(
                                Text(String(format: String(localized: "listing.detail.imageCounterFormat"), min(selection + 1, imagePaths.count), imagePaths.count))
                            )
                    }
                }
            }
            .padding(12)
            .padding(.bottom, bottomInset)
        }
        .frame(height: height)
        .clipped()
        .onChange(of: imagePaths) { _, _ in selection = 0 }
    }

    private var placeholder: some View {
        Rectangle().fill(Color.surfaceBackground)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled").font(
                    .system(size: 40)
                ).foregroundStyle(Color.iconColor)
            }
            .accessibilityLabel(Text("listing.detail.noImage"))
    }
}
