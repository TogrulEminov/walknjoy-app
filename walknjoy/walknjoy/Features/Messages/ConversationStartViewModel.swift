import Foundation
import Observation

@MainActor @Observable
final class ConversationStartViewModel {
    private(set) var conversationID: String?
    private(set) var isLoading = false
    var error: String?
    private var generation = UUID()
    func load(
        context: ConversationStart,
        locale: String,
        service: ConversationServiceProtocol
    ) async {
        guard !isLoading else { return }
        let epoch = generation
        isLoading = true
        error = nil
        do {
            let value = try await service.start(context, locale: locale)
            guard generation == epoch else { return }
            conversationID = value.id
        } catch is CancellationError {} catch {
            if generation == epoch { self.error = error.localizedDescription }
        }
        if generation == epoch { isLoading = false }
    }
    func invalidate() {
        generation = UUID()
        isLoading = false
        conversationID = nil
    }
}
