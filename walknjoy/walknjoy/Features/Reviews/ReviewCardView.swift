import SwiftUI

struct ReviewStarsView: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: value <= rating ? "star.fill" : "star")
                    .foregroundStyle(
                        value <= rating
                            ? Color.brandYellow : Color.descriptionText
                    )
            }
        }
        .font(.caption)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                String(
                    format: String(localized: "reviews.ratingFormat"),
                    rating
                )
            )
        )
    }
}

struct ReviewCardView: View {
    let name: String
    var avatar: String? = nil
    let rating: Int
    let title: String?
    let comment: String?
    let date: Date
    var verified = false
    var hidden = false
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var isBusy = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImageView(path: avatar) {
                    Circle().fill(Color.brandYellow.opacity(0.18))
                        .overlay {
                            Image(systemName: "person.fill").foregroundStyle(
                                Color.iconColor
                            )
                        }
                }
                .frame(width: 40, height: 40).clipShape(Circle())
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(name).font(.subheadline.weight(.semibold))
                    Text(
                        date,
                        format: .dateTime.day().month(.abbreviated).year()
                    )
                    .font(.caption).foregroundStyle(Color.descriptionText)
                }
                Spacer(minLength: 0)
                if onEdit != nil || onDelete != nil {
                    Menu {
                        if let onEdit {
                            Button(
                                "reviews.edit",
                                systemImage: "pencil",
                                action: onEdit
                            )
                        }
                        if let onDelete {
                            Button(
                                "reviews.delete",
                                systemImage: "trash",
                                role: .destructive,
                                action: onDelete
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis").frame(
                            width: 44,
                            height: 44
                        )
                    }
                    .disabled(isBusy)
                    .accessibilityLabel(Text("reviews.actions"))
                }
            }
            ReviewStarsView(rating: rating)
            if verified {
                Label(
                    "reviews.verifiedBooking",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.caption.weight(.semibold)).foregroundStyle(
                    Color.descriptionText
                )
            }
            if hidden {
                Label("reviews.hidden", systemImage: "eye.slash")
                    .font(.caption.weight(.semibold)).foregroundStyle(
                        Color.descriptionText
                    )
            }
            if let title = ReviewValidation.text(title) {
                Text(title).font(.subheadline.bold())
            }
            if let comment = ReviewValidation.text(comment) {
                Text(comment).font(.subheadline).foregroundStyle(
                    Color.descriptionText
                ).textSelection(.enabled)
            }
            if isBusy { ProgressView() }
        }
        .foregroundStyle(Color.titleText)
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.surfaceBackground,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(
                Color.borderColor,
                lineWidth: 1
            )
        }
    }
}

struct ReviewLoadStateView: View {
    let state: LoadState<Void>
    let isEmpty: Bool
    let retry: () -> Void
    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity).padding()
        case .error(let message):
            VStack(spacing: 12) {
                Text(message).font(.subheadline).foregroundStyle(
                    Color.errorColor
                )
                Button("common.retry", action: retry).frame(minHeight: 44)
            }.frame(maxWidth: .infinity)
        case .loaded:
            if isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.title3).foregroundStyle(Color.iconColor)
                        .frame(width: 40, height: 40)
                        .background(
                            Color.brandYellow.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    VStack(alignment: .leading, spacing: 5) {
                        Text("reviews.empty").font(
                            .subheadline.weight(.semibold)
                        ).foregroundStyle(Color.titleText)
                        Text("reviews.emptyDescription").font(.caption)
                            .foregroundStyle(Color.descriptionText)
                    }
                    Spacer(minLength: 0)
                }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.surfaceBackground,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
        }
    }
}
