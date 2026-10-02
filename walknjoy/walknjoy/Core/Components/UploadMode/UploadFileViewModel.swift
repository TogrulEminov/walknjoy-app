import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class UploadFileViewModel {

    private let uploadService: FileUploadServiceProtocol

    init(
        uploadService: FileUploadServiceProtocol? = nil
    ) {
        self.uploadService = uploadService ?? FileUploadService()
    }

    func handleSelection(
        _ selections: [PhotosPickerItem],
        mode: FileUploadMode,
        files: Binding<[UploadFileItem]>,
        onUploaded: ((UploadedFile) async -> Void)? = nil
    ) async {

        for selection in selections {

            guard files.wrappedValue.count < mode.maxCount else {
                break
            }

            do {
                guard
                    let data = try await selection.loadTransferable(
                        type: Data.self
                    )
                else {
                    continue
                }

                let item = UploadFileItem(
                    previewData: data
                )

                files.wrappedValue.append(item)

                await upload(
                    item,
                    files: files,
                    onUploaded: onUploaded
                )

            } catch {
                continue
            }
        }
    }

    func upload(
        _ item: UploadFileItem,
        files: Binding<[UploadFileItem]>,
        onUploaded: ((UploadedFile) async -> Void)? = nil
    ) async {

        updateState(
            id: item.id,
            state: .uploading,
            files: files
        )

        do {
            let input = UploadFileInput(
                data: item.previewData,
                fileName: "\(UUID().uuidString).jpg",
                mimeType: "image/jpeg"
            )

            let uploadedFile = try await uploadService.uploadOne(
                input
            )

            guard
                let index = files.wrappedValue.firstIndex(
                    where: { $0.id == item.id }
                )
            else {
                return
            }

            files.wrappedValue[index].uploadedFile = uploadedFile
            files.wrappedValue[index].state = .uploaded
            await onUploaded?(uploadedFile)

        } catch {
            updateState(
                id: item.id,
                state: .failed(error.localizedDescription),
                files: files
            )
        }
    }

    func retry(
        _ item: UploadFileItem,
        files: Binding<[UploadFileItem]>,
        onUploaded: ((UploadedFile) async -> Void)? = nil
    ) async {
        await upload(
            item,
            files: files,
            onUploaded: onUploaded
        )
    }

    func remove(
        _ item: UploadFileItem,
        files: Binding<[UploadFileItem]>
    )  async {

        if let uploadedFile = item.uploadedFile {
            do {
                try await uploadService.deleteOne(
                    id: uploadedFile.id
                )
            } catch {
                
               
                return
            }
        }

        files.wrappedValue.removeAll {
            $0.id == item.id
        }
    }

    private func updateState(
        id: UUID,
        state: UploadFileItemState,
        files: Binding<[UploadFileItem]>
    ) {
        guard
            let index = files.wrappedValue.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        files.wrappedValue[index].state = state
    }
}
