import Foundation
import Observation

@MainActor @Observable
final class ConversationStartViewModel {
    private(set) var state: LoadState<String> = .idle
    var conversationID: String? {
        if case .loaded(let id) = state { return id }
        return nil
    }
    var isLoading: Bool { state.isLoading }
    var error: String? { state.errorMessage }
    private var generation = UUID()
    func load(
        context: ConversationStart,
        locale: String,
        service: ConversationServiceProtocol
    ) async {
        guard !isLoading else { return }
        let epoch = generation
        state = .loading
        do {
            let value = try await service.start(context, locale: locale)
            guard generation == epoch else { return }
            state = .loaded(value.id)
        } catch is CancellationError {} catch {
            if generation == epoch {
                state = .error(error.localizedDescription)
            }
        }
        if generation == epoch, state.isLoading { state = .idle }
    }
    func invalidate() {
        generation = UUID()
        state = .idle
    }
}
