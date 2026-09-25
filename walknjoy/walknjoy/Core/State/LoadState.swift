import Foundation

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case error(String)
}

extension LoadState: Equatable where Value: Equatable {}
