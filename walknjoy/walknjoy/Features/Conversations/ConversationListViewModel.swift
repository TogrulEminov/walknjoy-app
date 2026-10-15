import Foundation
import Observation

@MainActor
@Observable
final class ConversationListViewModel {
    private let service: ConversationServiceProtocol
    private var generation = UUID()
    private var page = 0
    private(set) var rows: [ConversationRow] = []
    private(set) var state: LoadState<Void> = .idle
    private(set) var paginationState: LoadState<Void> = .idle
    var isLoading: Bool { state.isLoading || paginationState.isLoading }
    private(set) var hasMore = false
    var error: String? { state.errorMessage ?? paginationState.errorMessage }
    init(service: ConversationServiceProtocol) { self.service = service }
    func refresh(locale: String) async {
        guard !state.isLoading else { return }
        generation = UUID()
        let epoch = generation
        state = .loading
        paginationState = .idle
        defer {
            if generation == epoch {
                if state.isLoading { state = page > 0 ? .loaded(()) : .idle }
            }
        }
        do {
            let value = try await service.list(page: 1, locale: locale)
            guard generation == epoch else { return }
            var ids = Set<String>()
            rows = value.items.filter { ids.insert($0.id).inserted }
            page = value.meta.page
            hasMore = value.meta.hasNextPage
            state = .loaded(())
        } catch is CancellationError {} catch {
            if generation == epoch {
                state = .error(error.localizedDescription)
            }
        }
    }
    func loadMore(locale: String) async {
        guard !isLoading else { return }
        guard page > 0 else {
            await refresh(locale: locale)
            return
        }
        guard hasMore else { return }
        let epoch = generation
        paginationState = .loading
        do {
            let value = try await service.list(page: page + 1, locale: locale)
            guard generation == epoch else { return }
            var ids = Set(rows.map(\.id))
            rows += value.items.filter { ids.insert($0.id).inserted }
            page = value.meta.page
            hasMore = value.meta.hasNextPage
            paginationState = .loaded(())
        } catch is CancellationError {} catch {
            if generation == epoch {
                paginationState = .error(error.localizedDescription)
            }
        }
        if generation == epoch, paginationState.isLoading {
            paginationState = .idle
        }
    }
    func invalidate() {
        generation = UUID()
        rows = []
        page = 0
        hasMore = false
        state = .idle
        paginationState = .idle
    }
}
