import SwiftUI
import UIKit

/// Cache only successfully attached avatars, keyed by immutable uploaded file ID.
@MainActor
final class AvatarImageCache {
    static let shared = AvatarImageCache()
    private let images = NSCache<NSString, UIImage>()

    private init() { images.countLimit = 20 }

    func image(for id: String) -> UIImage? { images.object(forKey: id as NSString) }
    func store(_ image: UIImage, for id: String) { images.setObject(image, forKey: id as NSString) }
    func remove(_ id: String) { images.removeObject(forKey: id as NSString) }
}

struct AvatarImageView: View {
    let file: UploadedFile?
    let size: CGFloat
    @State private var image: UIImage?
    @State private var failed = false
    @State private var retry = 0

    private var identity: String { "\(file?.id ?? "")|\(file?.url ?? "")|\(retry)" }

    var body: some View {
        ZStack {
            Circle().fill(Color.disabledBackground)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else if failed {
                Button {
                    retry += 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("retry"))
            } else if file != nil {
                ProgressView().tint(Color.iconColor)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(Color.iconColor)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: identity) { await load() }
    }

    @MainActor
    private func load() async {
        failed = false
        image = nil
        guard let file else { return }
        if let cached = AvatarImageCache.shared.image(for: file.id) {
            image = cached
            return
        }
        guard let url = ImageURL.make(path: file.url) else {
            failed = true
            return
        }
        do {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            let (data, response) = try await URLSession.shared.data(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let loaded = UIImage(data: data) else {
                failed = true
                return
            }
            AvatarImageCache.shared.store(loaded, for: file.id)
            image = loaded
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }
}
