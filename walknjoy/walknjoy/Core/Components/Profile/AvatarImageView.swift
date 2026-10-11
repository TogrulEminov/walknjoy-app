import SwiftUI
import UIKit

struct AvatarImageView: View {
    let file: UploadedFile?
    let size: CGFloat
    @State private var model = AvatarImageViewModel()
    @State private var retry = 0

    private var identity: String {
        "\(file?.id ?? "")|\(file?.url ?? "")|\(retry)"
    }

    var body: some View {
        ZStack {
            Circle().fill(Color.disabledBackground)
            if let image = model.image {
                Image(uiImage: image).resizable().scaledToFill()
            } else if model.failed {
                Button {
                    retry += 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common.retry"))
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
        .task(id: identity) { await model.load(file: file) }
    }

}
