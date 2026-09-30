import Foundation

enum MobileAccountAccess {
    static func validate(role: String) throws {
        switch role.uppercased() {
        case "CUSTOMER", "PROVIDER": return
        default: throw AccessError.unsupportedRole
        }
    }

    enum AccessError: LocalizedError {
        case unsupportedRole
        var errorDescription: String? {
            String(localized: "auth.mobileAccessDenied")
        }
    }
}
