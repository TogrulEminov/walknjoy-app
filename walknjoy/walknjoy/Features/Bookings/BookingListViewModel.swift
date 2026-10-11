import Foundation
import Observation

@MainActor
@Observable
final class BookingListViewModel {
    private let service: BookingServiceProtocol
    let role: RoleEnum

    let pagination = PaginationController<BookingsModel>()
    var status: String? = nil
    var bookings: [BookingsModel] = []
    var state: LoadState<Void> = .idle
    var error: String?

    init(role: RoleEnum, service: BookingServiceProtocol? = nil) {
        self.role = role
        self.service = service ?? BookingService()
    }

    func loadMore() async {
        await pagination.loadNextPage()
        bookings = pagination.items
        if case .error(let message) = pagination.state { error = message }
    }

    func loadBookings() async {
        state = .loading
        error = nil

        do {
            switch role {
            case .customer:
                let service = service, filter = status
                await pagination.refresh { page, limit in
                    try await service.customerPage(page: page, limit: limit, status: filter)
                }
                bookings = pagination.items
                state = pagination.state
                return
            case .provider:
                bookings = try await service.getProviderBookings()
            case .admin:
                bookings = try await service.getAdminBookings()
            }
            state = .loaded(())
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
