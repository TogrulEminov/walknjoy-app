import Foundation
import SwiftUI

protocol FileUploadServiceProtocol {
    func uploadOne(_ input: UploadFileInput) async throws -> UploadedFile
    func deleteOne(id: String) async throws
}
final class FileUploadService: FileUploadServiceProtocol {
    enum Failure: Error { case offline }
    var fail = false
    func uploadOne(_ input: UploadFileInput) async throws -> UploadedFile {
        if fail { throw Failure.offline }
        return UploadedFile(id: "new", url: "new.jpg", originalName: "new.jpg", mimeType: "image/jpeg", sizeBytes: 1)
    }
    func deleteOne(id: String) async throws {}
}
@MainActor final class Store { var files: [UploadFileItem] = [] }
@main struct UploadChecks {
    @MainActor static func main() async {
        let store = Store()
        let binding = Binding(get: { store.files }, set: { store.files = $0 })
        let service = FileUploadService()
        let model = UploadFileViewModel(uploadService: service)
        var completions = 0
        let item = UploadFileItem(previewData: Data([1]))
        store.files = [item]
        service.fail = true
        await model.upload(item, files: binding) { _ in completions += 1 }
        precondition(completions == 0)
        service.fail = false
        await model.retry(item, files: binding) { file in
            precondition(file.id == "new" && store.files.first?.state == .uploaded)
            await Task.yield()
            completions += 1
            store.files = [] // The parent clears the item only after avatar attachment.
        }
        precondition(completions == 1 && store.files.isEmpty)
        print("PASS: failed upload does not attach; retry awaits exactly one completion; parent clearing is preserved")
    }
}
