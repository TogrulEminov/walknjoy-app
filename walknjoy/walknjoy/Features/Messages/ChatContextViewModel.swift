import Foundation
import Observation

@MainActor
@Observable
final class ChatContextViewModel {
    var listing: Listing?
    var error: String?
    func load(id: String, locale: String) async {
        do {
            listing = try await ListingServices().getListing(
                id: id,
                locale: locale
            )
        } catch { self.error = error.localizedDescription }
    }
}
