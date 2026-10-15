import Foundation

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case error(String)
}

extension LoadState: Equatable where Value: Equatable {}

extension LoadState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}
