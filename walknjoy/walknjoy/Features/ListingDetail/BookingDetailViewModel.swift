import Foundation
import Observation

@MainActor @Observable
final class BookingDetailViewModel {
    let bookingID: String
    let role: RoleEnum
    let service: BookingServiceProtocol
    let providerActions: ProviderBookingActionsModel

    var booking: BookingsModel?
    var ticketData: Data?
    var ownReview: MyReview?
    var reviewState: LoadState<Void> = .idle
    var isCancelling = false
    var isDeletingReview = false
    var listingDestination: Listing?
    private let reviews: any ReviewServiceProtocol
    private var reviewGeneration = UUID()
    var state: LoadState<Void> = .idle
    var error: String?

    init(
        bookingID: String,
        role: RoleEnum,
        service: BookingServiceProtocol? = nil,
        reviews: (any ReviewServiceProtocol)? = nil
    ) {
        self.reviews = reviews ?? ReviewService()
        self.bookingID = bookingID
        self.role = role
        let service = service ?? BookingService(network: DefaultNetworkService())
        self.service = service
        self.providerActions = ProviderBookingActionsModel(service: service)
    }

    func load(isRefreshing: Bool = false) async {
        if !isRefreshing || booking == nil { state = .loading }
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
            let message = role == .provider ? ProviderBookingError.message(error) : error.localizedDescription
            self.error = message
            if role == .provider, ProviderBookingError.isNotFound(error) { booking = nil }
            state = .error(message)
        }
    }

    func performProviderAction(_ action: ProviderBookingAction) async {
        guard role == .provider, let booking else { return }
        _ = await providerActions.perform(action, booking: booking)
        if providerActions.unavailableID == booking.id {
            self.booking = nil
            state = .error(String(localized: "provider.booking.notFound"))
        } else if let updated = providerActions.refreshedBooking {
            self.booking = updated
            state = .loaded(())
        }
        error = providerActions.error
    }

    func openListing(locale: String) async {
        guard let id = booking?.listing.id else { return }
        do {
            listingDestination = try await ListingServices().getListing(
                id: id,
                locale: locale
            )
        } catch {
            if error.isUnavailableListing { ListingLifecycle.shared.didDelete(id) }
            self.error = error.localizedDescription
        }
    }

    func loadReview(store: ReviewStore) async {
        guard role == .customer, booking?.status.uppercased() == "COMPLETED"
        else { return }
        let generation = UUID()
        reviewGeneration = generation
        let session = store.sessionID
        reviewState = .loading
        do {
            let history = try await reviews.allMine()
            guard reviewGeneration == generation, session == store.sessionID else { return }
            store.remember(history)
            if let review = history.first(where: { $0.bookingId == bookingID }) {
                ownReview = review
                reviewState = .loaded(())
                return
            }
            guard history.filter({ $0.listingId == booking?.listing.id })
                .allSatisfy({ ReviewValidation.text($0.bookingId) != nil })
            else { throw ReviewEligibilityError.missingBookingID }
            ownReview = nil
            reviewState = .loaded(())
        } catch {
            guard reviewGeneration == generation, session == store.sessionID else { return }
            reviewState = .error(error.localizedDescription)
        }
    }

    func deleteReview(store: ReviewStore, locale: String) async {
        guard !isDeletingReview, let review = ownReview else { return }
        isDeletingReview = true
        let session = store.sessionID
        defer { isDeletingReview = false }
        do {
            try await reviews.delete(id: review.id)
            guard session == store.sessionID else { return }
            ownReview = nil
            store.changed(listingID: review.listingId, review: nil, reviewID: review.id)
            if let slug = ReviewValidation.text(review.listing.slug) {
                await store.refreshRating(listingID: review.listingId, slug: slug, locale: locale, service: reviews)
            }
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
