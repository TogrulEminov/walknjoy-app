import PhotosUI
import SwiftUI

struct UploadFileView<PickerLabel: View>: View {
    let mode: FileUploadMode

    @Binding var files: [UploadFileItem]

    private let showsPreviews: Bool
    private let onRemove: ((UploadFileItem) async -> Bool)?
    private let onUploaded: ((UploadedFile) async -> Void)?
    private let pickerLabel: () -> PickerLabel

    @State private var isSelecting = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var viewModel = UploadFileViewModel()

    init(
        mode: FileUploadMode,
        files: Binding<[UploadFileItem]>,
        showsPreviews: Bool = true,
        onRemove: ((UploadFileItem) async -> Bool)? = nil,
        onUploaded: ((UploadedFile) async -> Void)? = nil,
        @ViewBuilder pickerLabel: @escaping () -> PickerLabel
    ) {
        self.mode = mode
        self._files = files
        self.showsPreviews = showsPreviews
        self.onRemove = onRemove
        self.onUploaded = onUploaded
        self.pickerLabel = pickerLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsPreviews && !files.isEmpty {
                previews
            }
 
            if mode == .single || files.count < mode.maxCount {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: selectionLimit,
                    matching: .images
                ) {
                    pickerLabel()
                }
                .buttonStyle(.plain)
                .disabled(isSelecting)
            }
        }
        .onChange(of: selectedItems) { _, items in
            handleSelection(items)
        }
    }
}

// MARK: - Selection

extension UploadFileView {
    fileprivate var selectionLimit: Int {
        if mode == .single {
            return 1
        }

        return max(mode.maxCount - files.count, 1)
    }

    fileprivate func handleSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty, !isSelecting else { return }
        isSelecting = true

        Task {
            defer {
                selectedItems = []
                isSelecting = false
            }
            if mode == .single {
                files = []
            }

            await viewModel.handleSelection(
                items,
                mode: mode,
                files: $files,
                onUploaded: onUploaded
            )

            selectedItems = []
        }
    }
}

// MARK: - Previews

extension UploadFileView {
    @ViewBuilder
    fileprivate var previews: some View {
        if mode == .single {
            if let item = files.first {
                singlePreview(item)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(files) { item in
                        multiplePreview(item)
                    }
                }
            }
        }
    }
}

// MARK: - Single Preview

extension UploadFileView {
    fileprivate func singlePreview(_ item: UploadFileItem) -> some View {
        ZStack {
            previewImage(
                item,
                width: nil,
                height: 200
            )

            stateOverlay(item)

            VStack {
                HStack {
                    Spacer()
                    removeButton(item)
                }

                Spacer()
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - Multiple Preview

extension UploadFileView {
    fileprivate func multiplePreview(_ item: UploadFileItem) -> some View {
        ZStack(alignment: .topTrailing) {
            previewImage(
                item,
                width: 64,
                height: 64
            )

            stateOverlay(item)

            removeButton(item)
                .padding(6)
        }
        .frame(width: 64, height: 64)
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }
}

// MARK: - Preview Image

extension UploadFileView {
    @ViewBuilder
    private func previewImage(
        _ item: UploadFileItem,
        width: CGFloat?,
        height: CGFloat
    ) -> some View {
        if let image = UIImage(data: item.previewData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: width == nil ? .infinity : nil
                )
                .frame(width: width, height: height)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.surfaceBackground)
                .frame(
                    maxWidth: width == nil ? .infinity : nil
                )
                .frame(width: width, height: height)
        }
    }
}

// MARK: - Upload State

extension UploadFileView {
    @ViewBuilder
    private func stateOverlay(_ item: UploadFileItem) -> some View {
        switch item.state {
        case .idle:
            EmptyView()

        case .uploading:
            ZStack {
                Color.black.opacity(0.40)

                VStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)

                    Text("upload.image.uploading")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }

        case .uploaded:
            uploadedBadge

        case .failed:
            failedOverlay(item)
        }
    }

    private var uploadedBadge: some View {
        VStack {
            Spacer()

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
                    .background(
                        Circle().fill(.white)
                    )

                Spacer()
            }
        }
        .padding(10)
    }

    private func failedOverlay(_ item: UploadFileItem) -> some View {
        ZStack {
            Color.black.opacity(0.50)

            Button {
                Task {
                    await viewModel.retry(
                        item,
                        files: $files,
                        onUploaded: onUploaded
                    )
                }
            } label: {
                VStack(spacing: 7) {
                    Image(
                        systemName: "arrow.clockwise.circle.fill"
                    )
                    .font(.system(size: 28))

                    Text("common.retry")
                        .font(
                            .caption.weight(.semibold)
                        )
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Remove

extension UploadFileView {
    private func removeButton(_ item: UploadFileItem) -> some View {
        Button {
            Task {
                await handleRemove(item)
            }
        } label: {
            Image(systemName: "xmark")
                .font(
                    .system(
                        size: 11,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.65))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func handleRemove(_ item: UploadFileItem) async {
        if let onRemove {
            let success = await onRemove(item)

            guard success else { return }

            files.removeAll {
                $0.id == item.id
            }

            return
        }

        await viewModel.remove(
            item,
            files: $files
        )
    }
}
