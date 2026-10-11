import Foundation
import UIKit

@MainActor protocol AvatarImageLoading {
    func load(file: UploadedFile) async throws -> UIImage
}

@MainActor protocol AvatarImageCaching {
    func storePreview(_ data: Data, for id: String)
    func remove(_ id: String)
}

@MainActor final class AvatarImageService: AvatarImageLoading, AvatarImageCaching {
    private let session: URLSession
    private let images = NSCache<NSString, UIImage>()
    static let shared = AvatarImageService()

    init(session: URLSession = .shared) { self.session = session; images.countLimit = 20 }
    func load(file: UploadedFile) async throws -> UIImage {
        if let cached = images.object(forKey: file.id as NSString) { return cached }
        guard let url = ImageURL.make(path: file.url) else { throw NetworkError.invalidURL }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let image = UIImage(data: data) else {
            throw NetworkError.invalidResponse
        }
        images.setObject(image, forKey: file.id as NSString)
        return image
    }
    func storePreview(_ data: Data, for id: String) {
        if let image = UIImage(data: data) { images.setObject(image, forKey: id as NSString) }
    }
    func remove(_ id: String) { images.removeObject(forKey: id as NSString) }
}

