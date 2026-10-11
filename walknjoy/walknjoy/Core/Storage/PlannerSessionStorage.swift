import Foundation

protocol PlannerSessionStoring {
    func sessionID(for account: String) -> String?
    func save(_ sessionID: String, for account: String)
    func remove(for account: String)
}

struct PlannerSessionStorage: PlannerSessionStoring {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func sessionID(for account: String) -> String? { defaults.string(forKey: key(account)) }
    func save(_ sessionID: String, for account: String) { defaults.set(sessionID, forKey: key(account)) }
    func remove(for account: String) { defaults.removeObject(forKey: key(account)) }
    private func key(_ account: String) -> String { "travelPlanner.session.\(account)" }
}
