import Foundation
import Observation

struct PaginationPage<Item> {
    let items: [Item]
    let meta: PaginationMeta?
    let hasMore: Bool?
    
    init(items: [Item], hasMore: Bool? = nil) {
        self.items = items
        self.meta = nil
        self.hasMore = hasMore
    }
    
    init(items: [Item], meta: PaginationMeta?) {
        self.items = items
        self.meta = meta
        self.hasMore = nil
    }
    
    func hasNextPage(currentPage: Int, limit: Int) -> Bool {
        if let meta { return meta.hasNextPage }
        return hasMore ?? (items.count == limit)
    }
}

@MainActor
@Observable
final class PaginationController<Item: Identifiable> {
    typealias FetchPage =
    @MainActor (_ page: Int, _ limit: Int) async throws -> PaginationPage<
        Item
    >
    
    private(set) var items: [Item] = []
    private(set) var meta: PaginationMeta?
    private(set) var nextPage = 1
    private(set) var hasMore = true
    private(set) var state: LoadState<Void> = .idle
    let limit: Int
    
    @ObservationIgnored private var fetchPage: FetchPage?
    @ObservationIgnored private var generation = UUID()
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    init(limit: Int = 20) {
        self.limit = max(1, limit)
    }
    func refresh(using fetchPage: @escaping FetchPage) async {
        self.fetchPage = fetchPage
        await refresh()
    }
    
    func refresh() async {
        generation = UUID()
        nextPage = 1
        hasMore = true
        state = .idle
        await loadNextPage()
    }
    
    func loadNextPage() async {
        guard !isLoading, hasMore, let fetchPage else { return }
        let requestGeneration = generation
        let page = nextPage
        state = .loading
        do {
            try Task.checkCancellation()
            let result = try await fetchPage(page, limit)
            guard generation == requestGeneration else { return }
            try Task.checkCancellation()
            if page == 1 { items = [] }
            var seen = Set(items.map(\.id))
            items.append(
                contentsOf: result.items.filter { seen.insert($0.id).inserted }
            )
            meta = result.meta
            nextPage = result.meta.map { $0.page + 1 } ?? (page + 1)
            hasMore = !result.items.isEmpty
            && result.hasNextPage(currentPage: page, limit: limit)
            state = .loaded(())
        } catch {
            guard generation == requestGeneration else { return }
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                // An idle state is rendered as a spinner by list views. End the
                // cancelled request explicitly and keep any previously loaded rows.
                state = items.isEmpty ? .error(URLError(.cancelled).localizedDescription) : .loaded(())
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    func loadNextPage(using fetchPage: @escaping FetchPage) async {
        self.fetchPage = fetchPage
        await loadNextPage()
    }
}
