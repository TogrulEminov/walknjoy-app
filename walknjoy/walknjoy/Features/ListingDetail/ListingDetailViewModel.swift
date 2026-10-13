import Foundation
import Observation

@MainActor
protocol ListingDetailServiceProtocol {
    func getListing(slug: String, locale: String, includeCustomerToken: Bool)
        async throws -> Listing
}

extension ListingServices: ListingDetailServiceProtocol {}

enum ListingDetailServiceFactory {
    static var makeDefault: () -> any ListingDetailServiceProtocol = {
        ListingServices()
    }
}
@Observable
@MainActor
final class ListingDetailViewModel {
    private let service: any ListingDetailServiceProtocol
    private var generation = UUID()
    private(set) var state: LoadState<Listing> = .idle
    private(set) var notFound = false
    private(set) var listing: Listing?

    init(service: (any ListingDetailServiceProtocol)? = nil) {
        self.service = service ?? ListingDetailServiceFactory.makeDefault()
    }
    func load(slug: String, locale: String, includeCustomerToken: Bool) async {
        generation = UUID()
        let request = generation
        notFound = false
        guard !slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            notFound = true
            state = .error(String(localized: "listing.detail.notFound"))
            return
        }
        state = .loading
        do {
            let listing = try await service.getListing(
                slug: slug,
                locale: locale,
                includeCustomerToken: includeCustomerToken
            )
            try Task.checkCancellation()
            guard generation == request else { return }
            self.listing = listing
            state = .loaded(listing)
        } catch is CancellationError {
            if generation == request { state = .idle }
        } catch {
            guard generation == request else { return }
            if let error = error as? NetworkError {
                switch error {
                case .listingNotFound, .notFound, .serverError(statusCode: 404):
                    notFound = true
                case .apiError(_, _, let statusCode):
                    notFound = statusCode == 404
                default: break
                }
            }
            if notFound { listing = nil }
            state = .error(
                notFound
                    ? String(localized: "listing.detail.notFound")
                    : error.localizedDescription
            )
        }
    }
}
