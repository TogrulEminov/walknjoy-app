import Foundation
import Observation

@MainActor
@Observable
final class BookingListViewModel {
    private let service: BookingServiceProtocol
    let role: RoleEnum
    let providerActions: ProviderBookingActionsModel
    private var generation = UUID()

    let pagination = PaginationController<BookingsModel>()
    var status: String? = nil
    var bookings: [BookingsModel] = []
    var state: LoadState<Void> = .idle
    var error: String?

    init(role: RoleEnum, service: BookingServiceProtocol? = nil) {
        self.role = role
        let service = service ?? BookingService(network: DefaultNetworkService())
        self.service = service
        self.providerActions = ProviderBookingActionsModel(service: service)
    }

    func loadMore() async {
        error = nil
        await pagination.loadNextPage()
        bookings = pagination.items
        if case .error(let message) = pagination.state { error = message }
    }

    func loadBookings(isRefreshing: Bool = false) async {
        let request = UUID()
        generation = request
        // Keep the ScrollView mounted while its native refresh indicator runs.
        let preserveContent: Bool
        if case .loaded = state {
            preserveContent = isRefreshing
        } else {
            preserveContent = false
        }
        if !preserveContent { state = .loading }
        error = nil

        do {
            switch role {
            case .customer, .provider:
                let service = service
                let filter = status
                let provider = role == .provider
                await pagination.refresh { page, limit in
                    if provider {
                        return try await service.providerPage(page: page, limit: limit, status: filter)
                    }
                    return try await service.customerPage(
                        page: page,
                        limit: limit,
                        status: filter
                    )
                }
                guard generation == request else { return }
                bookings = pagination.items
                if case .error(let message) = pagination.state, preserveContent {
                    error = message
                    state = .loaded(())
                } else {
                    state = pagination.state
                }
                return
            case .admin:
                bookings = try await service.getAdminBookings()
            }
            state = .loaded(())
        } catch {
            if preserveContent {
                self.error = error.localizedDescription
                state = .loaded(())
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }
    func performProviderAction(_ action: ProviderBookingAction, booking: BookingsModel) async {
        guard role == .provider else { return }
        _ = await providerActions.perform(action, booking: booking)
        applyProviderChange(providerActions.refreshedBooking, unavailableID: providerActions.unavailableID)
    }

    func applyProviderChange(_ updated: BookingsModel?, unavailableID: String? = nil) {
        if let unavailableID {
            bookings.removeAll { $0.id == unavailableID }
            pagination.remove(id: unavailableID)
        }
        guard let updated else { return }
        if let status, updated.status.uppercased() != status {
            bookings.removeAll { $0.id == updated.id }
            pagination.remove(id: updated.id)
        } else if let index = bookings.firstIndex(where: { $0.id == updated.id }) {
            bookings[index] = updated
            pagination.replace(updated)
        }
    }

}
