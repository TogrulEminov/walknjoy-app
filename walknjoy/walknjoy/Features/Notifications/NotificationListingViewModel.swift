import Foundation
import Observation

@MainActor @Observable
final class NotificationListingViewModel {
    private(set) var listing: Listing?
    private(set) var error: String?
    private var generation = UUID()
    private let service: ListingServicesProtocol

    init(service: ListingServicesProtocol? = nil) { self.service = service ?? ListingServices() }

    func load(slug: String, locale: String) async {
        let token = UUID()
        generation = token
        error = nil
        do {
            let result = try await service.getListing(slug: slug, locale: locale, includeCustomerToken: false)
            guard generation == token, !Task.isCancelled else { return }
            listing = result
        } catch {
            guard generation == token, !(error is CancellationError) else { return }
            self.error = String(localized: "notifications.destinationError")
        }
    }
}
