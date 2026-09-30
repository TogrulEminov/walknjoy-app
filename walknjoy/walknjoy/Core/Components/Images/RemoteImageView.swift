import Foundation
import SDWebImageSwiftUI
import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let placeholder: Placeholder

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder()
        
        print(url)
    }

    init(
        path: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.init(
            url: ImageURL.make(path: path),
            contentMode: contentMode,
            placeholder: placeholder
        )
    }

    var body: some View {
        ZStack {
            placeholder
            if let url {
                WebImage(url: url)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.fade(duration: 0.2))
            }
        }
    }
}
