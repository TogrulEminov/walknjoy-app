import Foundation

enum NetworkError: LocalizedError {
    // Lokal şəbəkə xətaları
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(details: String)
    case encodingError
    case noInternet
    case unknown(Error)

    // Ümumi API xətaları
    case validationError
    case badRequest
    case notFound
    case routeNotFound
    case conflict
    case internalServerError
    case unauthorized
    case forbidden

    // Auth və token
    case tokenExpired
    case invalidCredentials
    case invalidRefreshToken
    case incorrectPassword
    case emailAlreadyExists
    case accountSuspended
    case emailNotVerified
    case invalidOTP
    case otpExpired
    case otpTooManyAttempts
    case otpResendTooSoon
    case invalidResetToken
    case resetTokenExpired
    case invalidChangePasswordToken
    case changePasswordTokenExpired
    case invalidEmailVerificationToken
    case emailVerificationTokenExpired

    // Profil və fayllar
    case invalidAvatarType
    case avatarTooLarge
    case fileNotFound
    case fileTooLarge
    case fileAlreadyPublished

    // Xidmət təminatçıları
    case providerProfileAlreadyExists
    case providerProfileNotFound
    case providerNotApproved
    case invalidProviderStatus

    // Kateqoriyalar və imkanlar
    case categoryNotFound
    case categorySlugConflict
    case amenityNotFound
    case invalidAmenity

    // Elanlar
    case listingNotFound
    case listingSlugConflict
    case invalidListingStatus
    case invalidListingCategory
    case listingTypeChangeNotAllowed
    case listingDetailTypeMismatch

    // Elan şəkilləri
    case invalidMediaFileType
    case mediaFileTooLarge
    case mediaLimitReached
    case mediaNotFound

    // Əlçatanlıq
    case availabilityNotFound
    case invalidDateRange
    case invalidTimeRange
    case stayBlockPeriodOverlap
    case listingTypeNotSupported
    case sessionNotFound

    // Rezervasiyalar
    case bookingNotFound
    case bookingStatusTransitionInvalid
    case bookingCannotBeCancelled
    case bookingCannotBeConfirmed
    case bookingCannotBeCompleted
    case listingNotBookable
    case stayDateUnavailable
    case sessionCapacityExceeded
    case sessionNotAvailable
    case maxGuestsExceeded
    case minimumNightsNotMet
    case idempotencyKeyRequired
    case idempotencyKeyReused

    // Ödənişlər
    case paymentNotFound
    case bookingNotPayable
    case paymentAlreadyCompleted
    case invalidWebhookSignature
    case invoiceNotFound

    // Seçilmişlər və rəylər
    case listingNotFavoritable
    case reviewNotFound
    case reviewAlreadyExists
    case reviewBookingNotCompleted
    case reviewStatusTransitionInvalid

    // Söhbətlər və mesajlar
    case conversationNotFound
    case notConversationParticipant
    case cannotMessageSelf
    case listingNotInquirable
    case messageNotFound
    case clientMessageIdReused
    case invalidCursor

    // Bildirişlər
    case notificationNotFound

    // Backend-dən gələn naməlum kod
    case apiError(
        code: String,
        message: String,
        statusCode: Int
    )
}

extension NetworkError {
    var errorDescription: String? {
        switch self {
        // Lokal şəbəkə xətaları
        case .invalidURL:
            return "URL düzgün deyil."
        case .invalidResponse:
            return "Serverdən düzgün cavab alınmadı."
        case .serverError(let statusCode):
            return "Server xətası baş verdi. Kod: \(statusCode)"
        case .decodingError(let details):
            return "Serverdən gələn məlumat oxuna bilmədi. (details)"
        case .encodingError:
            return "Göndərilən məlumat hazırlanmadı."
        case .noInternet:
            return "İnternet bağlantısı yoxdur."
        case .unknown(let error):
            return error.localizedDescription

        // Ümumi API xətaları
        case .validationError:
            return "Daxil edilən məlumatları yoxlayın."
        case .badRequest:
            return "Sorğu düzgün deyil."
        case .notFound:
            return "Axtarılan məlumat tapılmadı."
        case .routeNotFound:
            return "Sorğu ünvanı tapılmadı."
        case .conflict:
            return "Əməliyyat mövcud məlumatla ziddiyyət təşkil edir."
        case .internalServerError:
            return "Server xətası baş verdi."
        case .unauthorized:
            return "Giriş üçün icazə yoxdur."
        case .forbidden:
            return "Bu əməliyyatı yerinə yetirmək üçün icazəniz yoxdur."

        // Auth və token
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
        case .emailNotVerified:
            return "E-poçt ünvanınızı təsdiqləməlisiniz."
        case .invalidOTP:
            return "Təsdiq kodu yanlışdır və ya etibarsızdır."
        case .otpExpired:
            return "Təsdiq kodunun vaxtı bitib."
        case .otpTooManyAttempts:
            return "Çox sayda yanlış cəhd edilib."
        case .otpResendTooSoon:
            return "Yeni kod istəməzdən əvvəl bir az gözləyin."
        case .invalidResetToken:
            return "Şifrə sıfırlama linki etibarsızdır."
        case .resetTokenExpired:
            return "Şifrə sıfırlama linkinin vaxtı bitib."
        case .invalidChangePasswordToken:
            return "Şifrə dəyişmə tokeni etibarsızdır."
        case .changePasswordTokenExpired:
            return "Şifrə dəyişmə tokeninin vaxtı bitib."
        case .invalidEmailVerificationToken:
            return "E-poçt təsdiq linki etibarsızdır."
        case .emailVerificationTokenExpired:
            return "E-poçt təsdiq linkinin vaxtı bitib."

        // Profil və fayllar
        case .invalidAvatarType:
            return "Avatar JPEG, PNG və ya WebP formatında olmalıdır."
        case .avatarTooLarge:
            return "Avatarın ölçüsü icazə verilən həddi keçir."
        case .fileNotFound:
            return "Fayl tapılmadı və ya ona giriş yoxdur."
        case .fileTooLarge:
            return "Faylın ölçüsü icazə verilən həddi keçir."
        case .fileAlreadyPublished:
            return "Artıq istifadə olunan faylı bu üsulla silmək olmaz."

        // Xidmət təminatçıları
        case .providerProfileAlreadyExists:
            return "Xidmət təminatçısı profili artıq mövcuddur."
        case .providerProfileNotFound:
            return "Xidmət təminatçısı profili tapılmadı."
        case .providerNotApproved:
            return "Xidmət təminatçısı hələ təsdiqlənməyib."
        case .invalidProviderStatus:
            return "Bu status dəyişikliyi mümkün deyil."

        // Kateqoriyalar və imkanlar
        case .categoryNotFound:
            return "Kateqoriya tapılmadı."
        case .categorySlugConflict:
            return "Bu kateqoriya ünvanı artıq istifadə olunur."
        case .amenityNotFound:
            return "İmkan tapılmadı."
        case .invalidAmenity:
            return "Seçilmiş imkanlardan biri etibarsızdır."

        // Elanlar
        case .listingNotFound:
            return "Elan tapılmadı və ya əlçatan deyil."
        case .listingSlugConflict:
            return "Bu elan ünvanı artıq istifadə olunur."
        case .invalidListingStatus:
            return "Elanın statusunu bu şəkildə dəyişmək olmaz."
        case .invalidListingCategory:
            return "Elan üçün seçilən kateqoriya etibarsızdır."
        case .listingTypeChangeNotAllowed:
            return "Bu elanın növünü dəyişmək olmaz."
        case .listingDetailTypeMismatch:
            return "Elanın məlumatlarında uyğunsuzluq var."

        // Elan şəkilləri
        case .invalidMediaFileType:
            return "Şəkil JPEG, PNG və ya WebP formatında olmalıdır."
        case .mediaFileTooLarge:
            return "Şəklin ölçüsü icazə verilən həddi keçir."
        case .mediaLimitReached:
            return "Əlavə edilə bilən şəkil sayına çatmısınız."
        case .mediaNotFound:
            return "Şəkil tapılmadı."

        // Əlçatanlıq
        case .availabilityNotFound:
            return "Bloklanmış dövr tapılmadı."
        case .invalidDateRange:
            return "Tarix aralığı yanlışdır."
        case .invalidTimeRange:
            return "Saat aralığı yanlışdır."
        case .stayBlockPeriodOverlap:
            return "Seçilən dövr mövcud blokla üst-üstə düşür."
        case .listingTypeNotSupported:
            return "Bu əməliyyat həmin elan növü üçün mümkün deyil."
        case .sessionNotFound:
            return "Seans tapılmadı."

        // Rezervasiyalar
        case .bookingNotFound:
            return "Rezervasiya tapılmadı."
        case .bookingStatusTransitionInvalid:
            return "Rezervasiyanın statusunu bu şəkildə dəyişmək olmaz."
        case .bookingCannotBeCancelled:
            return "Bu rezervasiyanı ləğv etmək olmaz."
        case .bookingCannotBeConfirmed:
            return "Bu rezervasiyanı təsdiqləmək olmaz."
        case .bookingCannotBeCompleted:
            return "Bu rezervasiyanı tamamlamaq olmaz."
        case .listingNotBookable:
            return "Bu elan hazırda rezervasiya üçün əlçatan deyil."
        case .stayDateUnavailable:
            return "Seçilən tarixlər artıq tutulub."
        case .sessionCapacityExceeded:
            return "Bu seansda boş yer qalmayıb."
        case .sessionNotAvailable:
            return "Bu seans rezervasiya üçün əlçatan deyil."
        case .maxGuestsExceeded:
            return "Qonaq sayı icazə verilən həddi keçir."
        case .minimumNightsNotMet:
            return "Minimum gecə sayı şərti ödənmir."
        case .idempotencyKeyRequired:
            return "Sorğu üçün tələb olunan identifikator yoxdur."
        case .idempotencyKeyReused:
            return "Bu sorğu identifikatoru başqa məlumatla istifadə olunub."

        // Ödənişlər
        case .paymentNotFound:
            return "Ödəniş tapılmadı."
        case .bookingNotPayable:
            return "Bu rezervasiya üçün ödəniş etmək olmaz."
        case .paymentAlreadyCompleted:
            return "Ödəniş artıq tamamlanıb."
        case .invalidWebhookSignature:
            return "Ödəniş bildirişinin imzası etibarsızdır."
        case .invoiceNotFound:
            return "Faktura tapılmadı."

        // Seçilmişlər və rəylər
        case .listingNotFavoritable:
            return "Bu elanı seçilmişlərə əlavə etmək mümkün deyil."
        case .reviewNotFound:
            return "Rəy tapılmadı."
        case .reviewAlreadyExists:
            return "Bu rezervasiya üçün artıq rəy yazılıb."
        case .reviewBookingNotCompleted:
            return "Rəy yazmaq üçün rezervasiya tamamlanmalıdır."
        case .reviewStatusTransitionInvalid:
            return "Rəyin statusunu bu şəkildə dəyişmək olmaz."

        // Söhbətlər və mesajlar
        case .conversationNotFound:
            return "Söhbət tapılmadı."
        case .notConversationParticipant:
            return "Bu söhbətin iştirakçısı deyilsiniz."
        case .cannotMessageSelf:
            return "Özünüzə mesaj göndərə bilməzsiniz."
        case .listingNotInquirable:
            return "Bu elanla bağlı sorğu göndərmək mümkün deyil."
        case .messageNotFound:
            return "Mesaj tapılmadı."
        case .clientMessageIdReused:
            return
                "Mesaj identifikatoru artıq başqa mesaj üçün istifadə olunub."
        case .invalidCursor:
            return "Səhifələmə məlumatı etibarsızdır."

        // Bildirişlər
        case .notificationNotFound:
            return "Bildiriş tapılmadı."

        case .apiError(_, let message, _):
            return message
        }
    }
}

extension NetworkError {
    static func from(
        code: String,
        message: String,
        statusCode: Int
    ) -> NetworkError {
        switch code {
        // Ümumi API xətaları
        case "VALIDATION_ERROR": return .validationError
        case "BAD_REQUEST": return .badRequest
        case "NOT_FOUND": return .notFound
        case "ROUTE_NOT_FOUND": return .routeNotFound
        case "CONFLICT": return .conflict
        case "INTERNAL_SERVER_ERROR": return .internalServerError
        case "UNAUTHORIZED": return .unauthorized
        case "FORBIDDEN": return .forbidden

        // Auth və token
        case "TOKEN_EXPIRED": return .tokenExpired
        case "INVALID_CREDENTIALS": return .invalidCredentials
        case "INVALID_REFRESH_TOKEN": return .invalidRefreshToken
        case "INCORRECT_PASSWORD": return .incorrectPassword
        case "EMAIL_ALREADY_EXISTS": return .emailAlreadyExists
        case "ACCOUNT_SUSPENDED": return .accountSuspended
        case "EMAIL_NOT_VERIFIED": return .emailNotVerified
        case "INVALID_OTP": return .invalidOTP
        case "OTP_EXPIRED": return .otpExpired
        case "OTP_TOO_MANY_ATTEMPTS": return .otpTooManyAttempts
        case "OTP_RESEND_TOO_SOON": return .otpResendTooSoon
        case "INVALID_RESET_TOKEN": return .invalidResetToken
        case "RESET_TOKEN_EXPIRED": return .resetTokenExpired
        case "INVALID_CHANGE_PASSWORD_TOKEN": return .invalidChangePasswordToken
        case "CHANGE_PASSWORD_TOKEN_EXPIRED": return .changePasswordTokenExpired
        case "INVALID_EMAIL_VERIFICATION_TOKEN":
            return .invalidEmailVerificationToken
        case "EMAIL_VERIFICATION_TOKEN_EXPIRED":
            return .emailVerificationTokenExpired

        // Profil və fayllar
        case "INVALID_AVATAR_TYPE": return .invalidAvatarType
        case "AVATAR_TOO_LARGE": return .avatarTooLarge
        case "FILE_NOT_FOUND": return .fileNotFound
        case "FILE_TOO_LARGE": return .fileTooLarge
        case "FILE_ALREADY_PUBLISHED": return .fileAlreadyPublished

        // Xidmət təminatçıları
        case "PROVIDER_PROFILE_ALREADY_EXISTS":
            return .providerProfileAlreadyExists
        case "PROVIDER_PROFILE_NOT_FOUND": return .providerProfileNotFound
        case "PROVIDER_NOT_APPROVED": return .providerNotApproved
        case "INVALID_PROVIDER_STATUS": return .invalidProviderStatus

        // Kateqoriyalar və imkanlar
        case "CATEGORY_NOT_FOUND": return .categoryNotFound
        case "CATEGORY_SLUG_CONFLICT": return .categorySlugConflict
        case "AMENITY_NOT_FOUND": return .amenityNotFound
        case "INVALID_AMENITY": return .invalidAmenity

        // Elanlar
        case "LISTING_NOT_FOUND": return .listingNotFound
        case "LISTING_SLUG_CONFLICT": return .listingSlugConflict
        case "INVALID_LISTING_STATUS": return .invalidListingStatus
        case "INVALID_LISTING_CATEGORY": return .invalidListingCategory
        case "LISTING_TYPE_CHANGE_NOT_ALLOWED":
            return .listingTypeChangeNotAllowed
        case "LISTING_DETAIL_TYPE_MISMATCH": return .listingDetailTypeMismatch

        // Elan şəkilləri
        case "INVALID_MEDIA_FILE_TYPE": return .invalidMediaFileType
        case "MEDIA_FILE_TOO_LARGE": return .mediaFileTooLarge
        case "MEDIA_LIMIT_REACHED": return .mediaLimitReached
        case "MEDIA_NOT_FOUND": return .mediaNotFound

        // Əlçatanlıq
        case "AVAILABILITY_NOT_FOUND": return .availabilityNotFound
        case "INVALID_DATE_RANGE": return .invalidDateRange
        case "INVALID_TIME_RANGE": return .invalidTimeRange
        case "STAY_BLOCK_PERIOD_OVERLAP": return .stayBlockPeriodOverlap
        case "LISTING_TYPE_NOT_SUPPORTED": return .listingTypeNotSupported
        case "SESSION_NOT_FOUND": return .sessionNotFound

        // Rezervasiyalar
        case "BOOKING_NOT_FOUND": return .bookingNotFound
        case "BOOKING_STATUS_TRANSITION_INVALID":
            return .bookingStatusTransitionInvalid
        case "BOOKING_CANNOT_BE_CANCELLED": return .bookingCannotBeCancelled
        case "BOOKING_CANNOT_BE_CONFIRMED": return .bookingCannotBeConfirmed
        case "BOOKING_CANNOT_BE_COMPLETED": return .bookingCannotBeCompleted
        case "LISTING_NOT_BOOKABLE": return .listingNotBookable
        case "STAY_DATE_UNAVAILABLE": return .stayDateUnavailable
        case "SESSION_CAPACITY_EXCEEDED": return .sessionCapacityExceeded
        case "SESSION_NOT_AVAILABLE": return .sessionNotAvailable
        case "MAX_GUESTS_EXCEEDED": return .maxGuestsExceeded
        case "MINIMUM_NIGHTS_NOT_MET": return .minimumNightsNotMet
        case "IDEMPOTENCY_KEY_REQUIRED": return .idempotencyKeyRequired
        case "IDEMPOTENCY_KEY_REUSED": return .idempotencyKeyReused
 

        // Seçilmişlər və rəylər
        case "LISTING_NOT_FAVORITABLE": return .listingNotFavoritable
        case "REVIEW_NOT_FOUND": return .reviewNotFound
        case "REVIEW_ALREADY_EXISTS": return .reviewAlreadyExists
        case "REVIEW_BOOKING_NOT_COMPLETED": return .reviewBookingNotCompleted
        case "REVIEW_STATUS_TRANSITION_INVALID":
            return .reviewStatusTransitionInvalid

        // Söhbətlər və mesajlar
        case "CONVERSATION_NOT_FOUND": return .conversationNotFound
        case "NOT_CONVERSATION_PARTICIPANT": return .notConversationParticipant
        case "CANNOT_MESSAGE_SELF": return .cannotMessageSelf
        case "LISTING_NOT_INQUIRABLE": return .listingNotInquirable
        case "MESSAGE_NOT_FOUND": return .messageNotFound
        case "CLIENT_MESSAGE_ID_REUSED": return .clientMessageIdReused
        case "INVALID_CURSOR": return .invalidCursor

        // Bildirişlər
        case "NOTIFICATION_NOT_FOUND": return .notificationNotFound

        default:
            return .apiError(
                code: code,
                message: message,
                statusCode: statusCode
            )
        }
    }
}
