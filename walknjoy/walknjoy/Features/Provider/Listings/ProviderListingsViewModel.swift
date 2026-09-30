import Foundation
import Observation

@MainActor @Observable final class ProviderListingsViewModel {
    var query = ProviderListingsQuery()
    private let pagination: PaginationController<ProviderListingCardDTO>
    var listings: [ProviderListingCardDTO] { pagination.items }
    var loading: Bool { pagination.isLoading && listings.isEmpty }
    var loadingNext: Bool { pagination.isLoading && !listings.isEmpty }
    private(set) var mutatingID: String?
    var meta: PaginationMeta? { pagination.meta }
    var error: String?
    var mutationError: String?
    var nextPageError: String?
    private let service: ProviderListingsManaging

    init(service: ProviderListingsManaging? = nil) {
        self.service = service ?? ProviderListingService()
        self.pagination = PaginationController(limit: 20)
    }
    var hasMore: Bool { pagination.hasMore }
    var totalCount: Int { meta?.total ?? listings.count }

    func reload(debounce: Bool = false) async {
        let query = query
        error = nil
        nextPageError = nil
        let service = service
        await pagination.refresh { page, limit in
            if debounce && page == 1 {
                try await Task.sleep(for: .milliseconds(350))
            }
            var request = query
            request.page = page
            request.limit = limit
            let response = try await service.list(query: request)
            return PaginationPage(items: response.data ?? [], meta: response.meta)
        }
        if case .error(let message) = pagination.state {
            error = message
        }
    }
    func loadMore() async {
        guard !loading, !loadingNext, hasMore else { return }
        nextPageError = nil
        let query = query
        let service = service
        await pagination.loadNextPage(using: { page, limit in
            var request = query
            request.page = page
            request.limit = limit
            let response = try await service.list(query: request)
            return PaginationPage(items: response.data ?? [], meta: response.meta)
        })
        if case .error(let message) = pagination.state {
            nextPageError = message
        }
    }
    func archive(_ listing: ProviderListingCardDTO) async {
        guard listing.actions.canArchive, mutatingID == nil else { return }
        mutatingID = listing.id
        mutationError = nil
        defer { mutatingID = nil }
        do {
            _ = try await service.archive(id: listing.id)
            await reload()
        } catch { mutationError = error.localizedDescription }
    }
    func submit(_ listing: ProviderListingCardDTO) async {
        guard listing.actions.canSubmit, mutatingID == nil else { return }
        mutatingID = listing.id
        mutationError = nil
        defer { mutatingID = nil }
        do {
            _ = try await service.submit(id: listing.id)
            await reload()
        } catch { mutationError = error.localizedDescription }
    }
}
