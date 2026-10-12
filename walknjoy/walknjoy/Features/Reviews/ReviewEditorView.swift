import SwiftUI

struct ReviewEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    var onSuccess: () -> Void = {}
    @State private var model: ReviewEditorViewModel
    init(context: ReviewEditorContext, onSuccess: @escaping () -> Void = {}) {
        self.onSuccess = onSuccess
        _model = State(initialValue: ReviewEditorViewModel(context: context))
    }

    @ViewBuilder private func fieldError(_ key: String) -> some View {
        if let message = model.fieldErrors[key] {
            Text(message).font(.caption).foregroundStyle(Color.errorColor)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("reviews.rating") {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                model.rating = value
                            } label: {
                                Image(
                                    systemName: value <= model.rating
                                        ? "star.fill" : "star"
                                )
                                .font(.title2).frame(
                                    minWidth: 44,
                                    minHeight: 44
                                )
                                .foregroundStyle(
                                    value <= model.rating
                                        ? Color.brandYellow
                                        : Color.descriptionText
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                Text(
                                    String(
                                        format: String(
                                            localized: "reviews.ratingFormat"
                                        ),
                                        value
                                    )
                                )
                            )
                            .accessibilityAddTraits(
                                value == model.rating ? .isSelected : []
                            )
                        }
                    }
                }
                .listRowBackground(Color.surfaceBackground)
                Section {
                    fieldError("rating")
                    TextField(
                        "reviews.titleOptional",
                        text: $model.title,
                        axis: .vertical
                    )
                    counter(model.title.count, limit: 120)
                    fieldError("title")
                }
                .listRowBackground(Color.surfaceBackground)
                Section {
                    TextField(
                        "reviews.commentOptional",
                        text: $model.comment,
                        axis: .vertical
                    )
                    .lineLimit(5...12)
                    counter(model.comment.count, limit: 2000)
                    fieldError("comment")
                }
                .listRowBackground(Color.surfaceBackground)
                if let error = model.error {
                    Section {
                        Text(error).foregroundStyle(Color.errorColor)
                        if model.duplicate {
                            NavigationLink("profile.reviews") {
                                MyReviewsView()
                            }
                        }
                    }
                    .listRowBackground(Color.surfaceBackground)
                }
                Section {
                    SubmitButton(
                        title: model.context.reviewID == nil
                            ? "reviews.publish" : "reviews.save",
                        icon: nil,
                        isLoading: model.isSubmitting,
                        isDisabled: !model.canSubmit
                            || appState.currentUserRole != .customer
                    ) {
                        Task {
                            guard appState.currentUserRole == .customer,
                                appState.currentUserID != nil
                            else { return }
                            if await model.submit(
                                store: appState.reviews,
                                locale: appState.language.rawValue
                            ) {
                                onSuccess()
                                dismiss()
                            }
                        }
                    }
                }.listRowBackground(Color.clear)
            }
            .disabled(model.isSubmitting)
            .scrollContentBackground(.hidden).background(Color.appBackground)
            .navigationTitle(
                model.context.reviewID == nil ? "reviews.write" : "reviews.edit"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }.disabled(
                        model.isSubmitting
                    )
                }
            }
            .interactiveDismissDisabled(model.isSubmitting)
        }
    }
    private func counter(_ count: Int, limit: Int) -> some View {
        Text(verbatim: "\(count) / \(limit)")
            .font(.caption).monospacedDigit()
            .foregroundStyle(
                count > limit ? Color.errorColor : Color.descriptionText
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
