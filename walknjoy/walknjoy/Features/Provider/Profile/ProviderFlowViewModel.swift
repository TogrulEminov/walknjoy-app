import Foundation
import Observation

@MainActor
@Observable
final class ProviderFlowViewModel {
    enum State {
        case idle
        case loading
        case needsApplication
        case loaded(ProviderProfile)
        case error(String)
    }

    private let service: ProviderServiceProtocol
    private(set) var state: State = .idle

    init(service: ProviderServiceProtocol? = nil) {
        self.service = service ?? ProviderService()
    }

    func load() async {
        guard !isLoading else { return }
        state = .loading
        do {
            state = .loaded(try await service.getProfile())
        } catch NetworkError.providerProfileNotFound {
            state = .needsApplication
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func submitApplication(_ input: ProviderApplicationInput) async throws {
        state = .loaded(try await service.apply(input))
    }

    func updateProfile(_ input: UpdateProviderProfileInput) async throws {
        state = .loaded(try await service.updateProfile(input))
    }

    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
}
