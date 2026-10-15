import Foundation
import Observation
import SwiftUI

nonisolated enum ProviderBookingAction: String, Identifiable {
    case confirm, cancel, complete
    var id: String { rawValue }
    var expectedStatus: String {
        switch self {
        case .confirm: "CONFIRMED"
        case .cancel: "CANCELLED"
        case .complete: "COMPLETED"
        }
    }
    func title(for booking: BookingsModel) -> LocalizedStringKey {
        switch self {
        case .confirm: "provider.booking.confirm"
        case .cancel:
            booking.status.uppercased() == "PENDING"
                ? "provider.booking.decline" : "provider.booking.cancel"
        case .complete: "provider.booking.complete"
        }
    }
    var confirmation: LocalizedStringKey {
        switch self {
        case .confirm: "provider.booking.confirmPrompt"
        case .cancel: "provider.booking.cancelPrompt"
        case .complete: "provider.booking.completePrompt"
        }
    }
}

nonisolated extension BookingsModel {
    var canShowCustomerContact: Bool {
        ["CONFIRMED", "COMPLETED"].contains(status.uppercased())
    }
    func providerActions(now: Date = Date()) -> [ProviderBookingAction] {
        switch status.uppercased() {
        case "PENDING": return [.confirm, .cancel]
        case "CONFIRMED":
            return canProviderComplete(now: now)
                ? [.cancel, .complete] : [.cancel]
        default: return []
        }
    }
    func canProviderComplete(now: Date) -> Bool {
        guard status.uppercased() == "CONFIRMED" else { return false }
        if listing.type == .stay {
            guard let checkOut else { return false }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            guard let end = formatter.date(from: String(checkOut.prefix(10)))
            else { return false }
            return end <= now
        }
        guard let endsAt = session?.endsAt else { return false }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        let date =
            fractional.date(from: endsAt)
            ?? ISO8601DateFormatter().date(from: endsAt)
        return date.map { $0 <= now } ?? false
    }
}

nonisolated enum ProviderBookingError {
    static func message(_ error: Error) -> String {
        if let failure = error as? APIRequestFailure {
            switch failure.statusCode {
            case 403: return String(localized: "provider.booking.forbidden")
            case 404: return String(localized: "provider.booking.notFound")
            case 409:
                return String(localized: "provider.booking.conflict") + "\n"
                    + failure.error.message
            default: return failure.localizedDescription
            }
        }
        if case NetworkError.serverError(statusCode: 403) = error {
            return String(localized: "provider.booking.forbidden")
        }
        if case NetworkError.serverError(statusCode: 404) = error {
            return String(localized: "provider.booking.notFound")
        }
        return error.localizedDescription
    }
    static func isNotFound(_ error: Error) -> Bool {
        if let failure = error as? APIRequestFailure {
            return failure.statusCode == 404
        }
        if case NetworkError.serverError(statusCode: 404) = error {
            return true
        }
        return false
    }
}

@MainActor @Observable
final class ProviderBookingActionsModel {
    private let service: any BookingServiceProtocol
    private(set) var busyID: String?
    private(set) var refreshedBooking: BookingsModel?
    private(set) var unavailableID: String?
    var error: String?

    init(service: any BookingServiceProtocol) { self.service = service }

    func perform(_ action: ProviderBookingAction, booking: BookingsModel) async
        -> BookingsModel?
    {
        guard busyID == nil, booking.providerActions().contains(action) else {
            return nil
        }
        busyID = booking.id
        error = nil
        refreshedBooking = nil
        unavailableID = nil
        defer { busyID = nil }
        do {
            let result: BookingsModel
            switch action {
            case .confirm:
                result = try await service.confirmBooking(id: booking.id)
            case .cancel:
                result = try await service.cancelBooking(id: booking.id)
            case .complete:
                result = try await service.completeBooking(id: booking.id)
            }
            guard result.id == booking.id,
                result.status.uppercased() == action.expectedStatus
            else {
                throw NetworkError.invalidResponse
            }
            refreshedBooking = result
            NotificationCenter.default.post(
                name: .bookingsChanged,
                object: result
            )
            return result
        } catch is CancellationError {
            return nil
        } catch {
            self.error = ProviderBookingError.message(error)
            if ProviderBookingError.isNotFound(error) {
                unavailableID = booking.id
            } else {
                do {
                    refreshedBooking = try await service.getProviderBooking(
                        id: booking.id
                    )
                } catch {
                    if ProviderBookingError.isNotFound(error) {
                        unavailableID = booking.id
                    }
                }
            }
            NotificationCenter.default.post(
                name: .bookingsChanged,
                object: refreshedBooking
            )
            return nil
        }
    }
}

struct ProviderBookingActionButtons: View {
    let booking: BookingsModel
    let busy: Bool
    let onAction: (ProviderBookingAction) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(spacing: 12) {
                ForEach(booking.providerActions(now: context.date)) { action in
                    Button(role: action == .cancel ? .destructive : nil) {
                        onAction(action)
                    } label: {
                        Text(action.title(for: booking))
                            .font(.subheadline.bold()).frame(
                                maxWidth: .infinity,
                                minHeight: 44
                            )
                    }
                    .buttonStyle(.bordered)
                }
                if busy { ProgressView() }
            }
            .disabled(busy)
            .tint(Color.titleText)
        }
    }
}
