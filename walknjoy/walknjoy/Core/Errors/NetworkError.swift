import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case tokenExpired
    case invalidCredentials
    case invalidRefreshToken
    case incorrectPassword
    case emailAlreadyExists
    case accountSuspended
    case providerNotApproved
    case serverError(statusCode: Int)
    case decodingError
    case encodingError
    case noInternet
    case unknown(Error)

}
extension NetworkError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL düzgün deyil."

        case .invalidResponse:
            return "Serverdən düzgün cavab alınmadı."

        case .unauthorized:
            return "Giriş üçün icazə yoxdur."

        case .forbidden:
            return "Bu əməliyyatı yerinə yetirmək üçün icazəniz yoxdur."

        case .tokenExpired:
            return "Sessiyanızın vaxtı bitib. Yenidən daxil olun."

        case .invalidCredentials:
            return "E-poçt və ya şifrə yanlışdır."

        case .invalidRefreshToken:
            return "Sessiya yenilənə bilmədi. Yenidən daxil olun."

        case .incorrectPassword:
            return "Mövcud şifrə yanlışdır."

        case .emailAlreadyExists:
            return "Bu e-poçt ünvanı artıq qeydiyyatdan keçib."

        case .accountSuspended:
            return "Hesabınız dayandırılıb."

        case .providerNotApproved:
            return "Xidmət təminatçısı hələ təsdiqlənməyib."

        case .serverError(let statusCode):
            return "Server xətası baş verdi. Kod: \(statusCode)"

        case .decodingError:
            return "Serverdən gələn məlumat oxuna bilmədi."

        case .encodingError:
            return "Göndərilən məlumat hazırlanmadı."

        case .noInternet:
            return "İnternet bağlantısı yoxdur."

        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
extension NetworkError {
    static func from(code: String) -> NetworkError {
        switch code {
        case "UNAUTHORIZED":
            return .unauthorized

        case "FORBIDDEN":
            return .forbidden

        case "TOKEN_EXPIRED":
            return .tokenExpired

        case "INVALID_CREDENTIALS":
            return .invalidCredentials

        case "INVALID_REFRESH_TOKEN":
            return .invalidRefreshToken

        case "INCORRECT_PASSWORD":
            return .incorrectPassword

        case "EMAIL_ALREADY_EXISTS":
            return .emailAlreadyExists

        case "ACCOUNT_SUSPENDED":
            return .accountSuspended

        case "PROVIDER_NOT_APPROVED":
            return .providerNotApproved

        default:
            return .serverError(statusCode: 0)
        }
    }
}
