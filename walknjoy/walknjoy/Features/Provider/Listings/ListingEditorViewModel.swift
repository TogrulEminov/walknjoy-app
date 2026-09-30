import Foundation
import Observation

struct ListingTranslationDraft {
    var title = ""
    var slug = ""
    var shortDescription = ""
    var description = ""
    var district = ""
    var addressLine = ""
}

@MainActor @Observable
final class ListingEditorViewModel {
    let type: ListingType
    private(set) var id: String?
    private(set) var status: ListingStatus? = .draft
    private(set) var rejectionReason: String?
    private(set) var canEdit = true
    private(set) var canSubmit = true
    private(set) var locale: ListingLocale = .az
    var translation = ListingTranslationDraft()
    var categoryId: String?
    var price = ""
    var currency = "AZN"
    var cityId = ""
    var latitude = ""
    var longitude = ""
    var selectedAmenities: Set<String> = []
    var stay = StayDetails(propertyType: "apartment", maxGuests: 1)
    var tour = TourDetails(languages: [])
    var activity = ActivityDetails()
    var experience = ExperienceDetails()
    private(set) var categories: [CategoryModel] = []
    private(set) var amenities: [AmenityModel] = []
    private(set) var cities: [ListingCity] = []
    private(set) var busy = false
    private(set) var loaded = false
    var error: String?
    var notice: String?
    var refreshError: String?
    private(set) var media: [ProviderListingEditorDTO.Media] = []
    private var originalPrice = ""
    private var originalCurrency = "AZN"
    private var originalCategoryId: String?
    private var originalCityId = ""
    private var originalLatitude = ""
    private var originalLongitude = ""
    private var translations: [ListingLocale: ListingTranslationDraft] = [:]
    private let service: ProviderListingService

    init(
        type: ListingType,
        id: String? = nil,
        locale: ListingLocale = .az,
        canEdit: Bool = true,
        canSubmit: Bool = true,
        onMutation: @escaping @MainActor @Sendable () -> Void = {},
        service: ProviderListingService? = nil
    ) {
        self.type = type
        self.id = id
        self.locale = locale
        self.canEdit = canEdit
        self.canSubmit = canSubmit
        self.onMutation = onMutation
        self.service = service ?? ProviderListingService()
    }

    private let onMutation: @MainActor @Sendable () -> Void

    var editable: Bool { canEdit && status != .archived }
    var canSave: Bool { loaded && editable && valid && detailsValid && !busy }
    var canSubmitWithCurrentInput: Bool {
        canSubmit && loaded && valid && detailsValid && !busy
    }
    var hasUnsavedChanges: Bool {
        translation.title != (translations[locale]?.title ?? "")
            || translation.description
                != (translations[locale]?.description ?? "")
            || translation.slug != (translations[locale]?.slug ?? "")
            || translation.shortDescription
                != (translations[locale]?.shortDescription ?? "")
            || price != originalPrice || currency != originalCurrency
            || categoryId != originalCategoryId
            || cityId != originalCityId || latitude != originalLatitude
            || longitude != originalLongitude
    }
    var validationMessage: String? { nil }
    var valid: Bool {
        translation.title.listingNonBlank != nil
            && translation.description.listingNonBlank != nil
            && cityId.listingNonBlank != nil
            && ProviderListingValidation.price(price).map { $0 >= 0 } == true
            && currency.listingNonBlank != nil
            && Double(latitude).map { (-90...90).contains($0) } == true
            && Double(longitude).map { (-180...180).contains($0) } == true
    }
    var detailsValid: Bool {
        switch type {
        case .stay:
            return stay.propertyType.listingNonBlank != nil
                && stay.maxGuests > 0
                && [stay.bedrooms, stay.beds, stay.bathrooms].allSatisfy {
                    $0.map { $0 >= 0 } ?? true
                } && (stay.minimumNights.map { $0 > 0 } ?? true)
        case .tour:
            return positive(tour.durationMinutes)
                && positive(tour.maxParticipants)
                && nonnegative(tour.minimumAge)
        case .activity:
            return positive(activity.durationMinutes)
                && positive(activity.maxParticipants)
                && nonnegative(activity.minimumAge)
        case .experience:
            return positive(experience.durationMinutes)
                && positive(experience.maxParticipants)
                && nonnegative(experience.minimumAge)
        }
    }
    private func positive(_ value: Int?) -> Bool {
        value.map { $0 > 0 } ?? true
    }
    private func nonnegative(_ value: Int?) -> Bool {
        value.map { $0 >= 0 } ?? true
    }

    func load() async {
        guard !busy, !loaded else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            if let id {
                let listing = try await service.get(id: id)
                let details = try await service.getDetails(id: id)
                apply(listing)
                canEdit = canEdit && listing.status != .archived
                canSubmit =
                    canSubmit
                    && (listing.status == .draft || listing.status == .rejected)
                applyDetails(details)
            }
            try await loadTaxonomy(locale)
            loaded = true
        } catch { self.error = error.localizedDescription }
    }

    func refreshFromServer() async {
        guard let id, !busy else { return }
        busy = true
        refreshError = nil
        defer { busy = false }
        do {
            let listing = try await service.get(id: id)
            apply(listing)
            canEdit = listing.status != .archived
            canSubmit = listing.status == .draft || listing.status == .rejected
        } catch { refreshError = error.localizedDescription }
    }

    func addPhoto(_ data: Data) async {
        guard let id, editable, !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await service.uploadAndAddMedia(
                id: id,
                input: UploadFileInput(
                    data: data,
                    fileName: "\(UUID().uuidString).jpg",
                    mimeType: "image/jpeg"
                ),
                altText: translation.title.listingNonBlank
            )
            apply(try await service.get(id: id))
        } catch { self.error = error.localizedDescription }
    }

    func removeMedia(_ media: ProviderListingEditorDTO.Media) async {
        guard let id, editable, !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await service.deleteMedia(id: id, mediaId: media.id)
            apply(try await service.get(id: id))
        } catch { self.error = error.localizedDescription }
    }

    func changeLocale(_ next: ListingLocale) async {
        guard !busy, next != locale else { return }
        busy = true
        error = nil
        notice = nil
        defer { busy = false }
        translations[locale] = translation
        do {
            let nextTranslation: ListingTranslationDraft
            if let cached = translations[next] {
                nextTranslation = cached
            } else if let id {
                nextTranslation = draft(
                    try await service.get(id: id),
                    locale: next
                )
            } else {
                nextTranslation = ListingTranslationDraft()
            }
            try await loadTaxonomy(next)
            locale = next
            translation = nextTranslation
        } catch { self.error = error.localizedDescription }
    }

    private func loadTaxonomy(_ locale: ListingLocale) async throws {
        async let categories = service.categories(type: type, locale: locale)
        async let amenities = service.amenities(type: type, locale: locale)
        async let cities = service.cities(locale: locale)
        let result = try await (categories, amenities, cities)
        self.categories = result.0
        self.amenities = result.1
        self.cities = result.2
    }

    func save(submit: Bool = false) async {
        guard !busy, loaded, editable, valid, detailsValid,
            let amount = ProviderListingValidation.price(price)
        else { return }
        if submit && !canSubmit { return }
        busy = true
        error = nil
        notice = nil
        defer { busy = false }
        let location = ProviderLocationRequest(
            locale: locale,
            cityId: cityId.listingNonBlank,
            latitude: Double(latitude),
            longitude: Double(longitude),
            district: patch(translation.district),
            addressLine: patch(translation.addressLine)
        )
        do {
            let saved: ProviderListingEditorDTO
            if let id, !hasTranslationChanges {
                let categoryChanged = categoryId != originalCategoryId
                let locationChanged =
                    cityId != originalCityId || latitude != originalLatitude
                    || longitude != originalLongitude
                if categoryChanged || locationChanged {
                    saved = try await service.update(
                        id: id,
                        input: UpdateListingRequest(
                            categoryId: categoryId.map(ProviderPatchValue.value)
                                ?? .null,
                            basePrice: amount,
                            currency: ProviderCurrency(rawValue: currency),
                            location: locationChanged ? location : nil
                        )
                    )
                } else {
                    saved = try await service.updatePrice(
                        id: id,
                        amount: amount,
                        currency: ProviderCurrency(rawValue: currency) ?? .AZN
                    )
                }
            } else if let id {
                saved = try await service.update(
                    id: id,
                    input: UpdateListingRequest(
                        locale: locale,
                        title: translation.title,
                        description: translation.description,
                        slug: patch(translation.slug),
                        shortDescription: patch(translation.shortDescription),
                        categoryId: categoryId.map(ProviderPatchValue.value)
                            ?? .null,
                        basePrice: amount,
                        currency: ProviderCurrency(rawValue: currency),
                        location: location
                    )
                )
            } else if let categoryId = categoryId {
                saved = try await service.create(
                    CreateListingRequest(
                        type: type,
                        categoryId: categoryId,
                        basePrice: amount,
                        currency: ProviderCurrency(rawValue: currency) ?? .AZN,
                        locale: locale,
                        title: translation.title,
                        description: translation.description,
                        slug: translation.slug.listingNonBlank,
                        shortDescription: translation.shortDescription
                            .listingNonBlank,
                        location: ProviderLocationRequest(
                            locale: locale,
                            cityId: cityId,
                            latitude: Double(latitude),
                            longitude: Double(longitude),
                            district: patch(translation.district),
                            addressLine: patch(translation.addressLine)
                        )
                    )
                )
            } else {
                saved = try await service.create(
                    CreateListingRequest(
                        type: type,
                        categoryId: nil,
                        basePrice: amount,
                        currency: ProviderCurrency(rawValue: currency) ?? .AZN,
                        locale: locale,
                        title: translation.title,
                        description: translation.description,
                        slug: translation.slug.listingNonBlank,
                        shortDescription: translation.shortDescription
                            .listingNonBlank,
                        location: location
                    )
                )
            }
            // Retain the new ID immediately: retry after a details failure must PATCH, never create twice.
            id = saved.id
            status = saved.status
            try await service.saveDetails(
                id: saved.id,
                input: ListingDetailsInput(
                    details: details,
                    amenityIds: selectedAmenities.sorted()
                )
            )
            if submit {
                status = try await service.submit(id: saved.id).status
                canSubmit = false
            }
            translations[locale] = translation
            notice =
                submit
                ? String(localized: "listing.notice.submitted")
                : String(localized: "listing.notice.saved")
            onMutation()
        } catch { self.error = error.localizedDescription }
    }

    private var details: ListingDetails {
        switch type {
        case .stay: .stay(stay)
        case .tour:
            .tour(
                TourDetails(
                    durationMinutes: tour.durationMinutes,
                    maxParticipants: tour.maxParticipants,
                    minimumAge: tour.minimumAge,
                    meetingPoint: tour.meetingPoint?.listingNonBlank,
                    languages: tour.languages.compactMap(\.listingNonBlank),
                    isPrivateTour: tour.isPrivateTour
                )
            )
        case .activity: .activity(activity)
        case .experience: .experience(experience)
        }
    }
    private var hasTranslationChanges: Bool {
        let original = translations[locale]
        guard let original else { return true }
        return original.title != translation.title
            || original.description != translation.description
            || original.slug != translation.slug
            || original.shortDescription != translation.shortDescription
            || original.district != translation.district
            || original.addressLine != translation.addressLine
    }
    private func patch(_ value: String) -> ProviderPatchValue<String> {
        value.listingNonBlank.map { .value($0) } ?? .null
    }

    private func draft(
        _ listing: ProviderListingEditorDTO,
        locale: ListingLocale
    ) -> ListingTranslationDraft {
        let content = listing.translations.first { $0.language == locale }
        let location = listing.location?.translations.first {
            $0.language == locale
        }
        return ListingTranslationDraft(
            title: content?.title ?? "",
            slug: content?.slug ?? "",
            shortDescription: content?.shortDescription ?? "",
            description: content?.description ?? "",
            district: location?.district ?? "",
            addressLine: location?.addressLine ?? ""
        )
    }

    private func apply(_ listing: ProviderListingEditorDTO) {
        status = listing.status
        rejectionReason = listing.rejectionReason
        for language in ListingLocale.allCases {
            translations[language] = draft(listing, locale: language)
        }
        translation = translations[locale] ?? ListingTranslationDraft()
        categoryId = listing.categoryId
        price = listing.basePrice
        currency = listing.currency
        cityId = listing.location?.cityId ?? ""
        latitude = listing.location.map { String($0.latitude) } ?? ""
        longitude = listing.location.map { String($0.longitude) } ?? ""
        media = listing.media
        originalPrice = price
        originalCurrency = currency
        originalCategoryId = categoryId
        originalCityId = cityId
        originalLatitude = latitude
        originalLongitude = longitude
    }

    private func applyDetails(_ listing: ProviderListingDetailsDTO) {
        selectedAmenities = Set(listing.amenities.map(\.id))
        switch listing.details {
        case .stay(let value): stay = value
        case .tour(let value): tour = value
        case .activity(let value): activity = value
        case .experience(let value): experience = value
        case nil: break
        }
    }
}
