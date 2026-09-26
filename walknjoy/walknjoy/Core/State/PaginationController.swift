import Foundation
import Observation

/// Adapts any paginated service response to the shared controller.
struct PaginationPage<Item> {
    let items: [Item]
    /// Leave nil when the endpoint only supports page-size based pagination.
    let hasMore: Bool?

    init(items: [Item], hasMore: Bool? = nil) {
        self.items = items
        self.hasMore = hasMore
    }
}

/// Own this controller in an observable ViewModel; views can observe its state.
@MainActor
@Observable
final class PaginationController<Item: Identifiable> {
    typealias FetchPage = @MainActor (_ page: Int, _ limit: Int) async throws -> PaginationPage<Item>

    private(set) var items: [Item] = []
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

    /// Replace the loader when filters or locale change. In-flight results are ignored.
    func refresh(using fetchPage: @escaping FetchPage) async {
        self.fetchPage = fetchPage
        await refresh()
    }

    func refresh() async {
        generation = UUID()
        items = []
        nextPage = 1
        hasMore = true
        state = .idle
        await loadNextPage()
    }

    /// Failures preserve existing items and the page number so this also retries.
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
            var seen = Set(items.map(\.id))
            items.append(contentsOf: result.items.filter { seen.insert($0.id).inserted })
            nextPage = page + 1
            hasMore = !result.items.isEmpty && (result.hasMore ?? (result.items.count == limit))
            state = .loaded(())
        } catch {
            guard generation == requestGeneration else { return }
            state = error is CancellationError ? .idle : .error(error.localizedDescription)
        }
    }
}
