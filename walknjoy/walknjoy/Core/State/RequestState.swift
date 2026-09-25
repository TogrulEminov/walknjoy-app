import Foundation

enum RequestState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
