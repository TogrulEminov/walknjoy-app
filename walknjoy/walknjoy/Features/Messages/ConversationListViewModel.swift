import Foundation
import Observation

@MainActor
@Observable
final class ConversationListViewModel {
    private let service: ConversationServiceProtocol
    private var generation = UUID()
    private var page = 0
    private(set) var rows: [ConversationRow] = []
    private(set) var isLoading = false
    private(set) var hasMore = false
    var error: String?
    init(service: ConversationServiceProtocol) { self.service = service }
    func refresh(locale: String) async {
        generation = UUID()
        page = 0
        rows = []
        isLoading = false
        await loadMore(locale: locale)
    }
    func loadMore(locale: String) async {
        guard !isLoading, page == 0 || hasMore else { return }
        let epoch = generation
        isLoading = true
        error = nil
        do {
            let value = try await service.list(page: page + 1, locale: locale)
            guard generation == epoch else { return }
            var ids = Set(rows.map(\.id))
            rows += value.items.filter { ids.insert($0.id).inserted }
            page = value.meta.page
            hasMore = value.meta.hasNextPage
        } catch is CancellationError {} catch {
            if generation == epoch { self.error = error.localizedDescription }
        }
        if generation == epoch { isLoading = false }
    }
    func invalidate() {
        generation = UUID()
        rows = []
        page = 0
        hasMore = false
        isLoading = false
    }
}
