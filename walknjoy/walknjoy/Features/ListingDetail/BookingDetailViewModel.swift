import Foundation
import Observation

@MainActor @Observable
final class BookingDetailViewModel {
    let bookingID: String
    let role: RoleEnum
    let service: BookingServiceProtocol

    var booking: BookingsModel?
    var ticketData: Data?
    var ownReview: MyReview?
    var reviewState: LoadState<Void> = .idle
    var isCancelling = false
    var isDeletingReview = false
    var listingDestination: Listing?
    private let reviews: any ReviewServiceProtocol = ReviewService()
    private var reviewGeneration = UUID()
    var state: LoadState<Void> = .idle
    var error: String?

    init(
        bookingID: String,
        role: RoleEnum,
        service: BookingServiceProtocol? = nil
    ) {
        self.bookingID = bookingID
        self.role = role
        self.service =
            service ?? BookingService(network: DefaultNetworkService())
    }

    func load() async {
        state = .loading
        error = nil
        do {
            switch role {
            case .customer:
                booking = try await service.getBooking(id: bookingID)
            case .provider:
                booking = try await service.getProviderBooking(id: bookingID)
            case .admin:
                booking = try await service.getAdminBooking(id: bookingID)
            }
            state = .loaded(())
        } catch {
            self.error = error.localizedDescription
            state = .error(error.localizedDescription)
        }
    }

    func openListing(locale: String) async {
        guard let id = booking?.listing.id else { return }
        do {
            listingDestination = try await ListingServices().getListing(
                id: id,
                locale: locale
            )
        } catch { self.error = error.localizedDescription }
    }

    func loadReview(store: ReviewStore) async {
        guard role == .customer, booking?.status.uppercased() == "COMPLETED"
        else { return }
        let generation = UUID()
        reviewGeneration = generation
        let session = store.sessionID
        reviewState = .loading
        do {
            var page = 1
            while true {
                let result = try await reviews.mine(page: page, limit: 100)
                try Task.checkCancellation()
                guard reviewGeneration == generation, session == store.sessionID
                else { return }
                store.remember(result.items)
                if let review = result.items.first(where: {
                    $0.bookingId == bookingID
                }) {
                    ownReview = review
                    reviewState = .loaded(())
                    return
                }
                if !result.hasNextPage(currentPage: page, limit: 100)
                    || result.items.isEmpty
                {
                    break
                }
                page += 1
            }
            ownReview = nil
            reviewState = .loaded(())
        } catch {
            guard reviewGeneration == generation else { return }
            reviewState = .error(error.localizedDescription)
        }
    }

    func deleteReview(store: ReviewStore) async {
        guard !isDeletingReview, let review = ownReview else { return }
        isDeletingReview = true
        defer { isDeletingReview = false }
        do {
            try await reviews.delete(id: review.id)
            ownReview = nil
            store.changed(listingID: review.listingId, review: nil)
        } catch { self.error = error.localizedDescription }
    }

    func cancel() async {
        guard !isCancelling, role == .customer, booking?.canCancel == true
        else { return }
        isCancelling = true
        defer { isCancelling = false }
        do {
            booking = try await service.cancelCustomerBooking(id: bookingID)
            NotificationCenter.default.post(name: .bookingsChanged, object: nil)
        } catch {
            await load()
            self.error = error.localizedDescription
        }
    }

    func loadTicket() async {
        do {
            ticketData = try await service.getBookingTicket(id: bookingID)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
