import Foundation
import Observation

// Locally confirmed deletions stay excluded even if a subsequent refresh fails.
@MainActor @Observable
final class ListingLifecycle {
    static let shared = ListingLifecycle()
    private(set) var deletedIDs: Set<String> = []

    func didDelete(_ id: String) {
        guard deletedIDs.insert(id).inserted else { return }
        NotificationCenter.default.post(name: .listingsChanged, object: id)
    }
}

nonisolated extension Error {
    var isUnavailableListing: Bool {
        guard let error = self as? NetworkError else { return false }
        switch error {
        case .listingNotFound, .notFound, .serverError(statusCode: 404): return true
        case .apiError(let code, _, let status):
            return status == 404 || ["LISTING_DELETED", "LISTING_NOT_FOUND"].contains(code)
        default: return false
        }
    }
}

nonisolated extension Foundation.Notification.Name {
    static let listingsChanged = Self("listingsChanged")
}
