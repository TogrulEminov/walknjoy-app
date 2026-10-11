import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AvatarImageViewModel {
    private(set) var image: UIImage?
    private(set) var failed = false
    private let service: AvatarImageLoading
    private var generation = UUID()

    init(service: AvatarImageLoading? = nil) {
        self.service = service ?? AvatarImageService.shared
    }
    func load(file: UploadedFile?) async {
        let token = UUID()
        generation = token
        failed = false
        image = nil
        guard let file else { return }
        do {
            let loaded = try await service.load(file: file)
            guard generation == token, !Task.isCancelled else { return }
            image = loaded
        } catch {
            if generation == token, !Task.isCancelled { failed = true }
        }
    }
}
