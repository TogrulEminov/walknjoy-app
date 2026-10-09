import Foundation

enum MockTravelData {
    static let categories: [CategoryModel] = [
        .init(id: "category-nature", name: "Təbiət", slug: "nature", description: "Təbiətdə istirahət və macəra", listingTypes: [.stay, .activity, .tour], order: 1),
        .init(id: "category-culture", name: "Mədəniyyət", slug: "culture", description: "Yerli tarix və mədəniyyət", listingTypes: [.tour, .experience], order: 2),
        .init(id: "category-food", name: "Yerli mətbəx", slug: "local-food", description: "Azərbaycan mətbəxini kəşf et", listingTypes: [.experience], order: 3)
    ]

    static let cities: [ListingCity] = [
        .init(id: "baku", name: "Bakı", latitude: 40.4093, longitude: 49.8671),
        .init(id: "sheki", name: "Şəki", latitude: 41.1919, longitude: 47.1706),
        .init(id: "gabala", name: "Qəbələ", latitude: 40.9814, longitude: 47.8458),
        .init(id: "qusar", name: "Qusar", latitude: 41.4275, longitude: 48.4302)
    ]

    static let destinations: [PopularDestination] = [
        .init(id: "destination-baku", city: "Bakı", listingCount: 18, counts: .init(stay: 5, tour: 6, activity: 4, experience: 3), coverImage: "https://images.unsplash.com/photo-1611124601904-8f7e7e2c7b49?w=1200"),
        .init(id: "destination-sheki", city: "Şəki", listingCount: 12, counts: .init(stay: 4, tour: 3, activity: 2, experience: 3), coverImage: "https://images.unsplash.com/photo-1590077428593-a55bb07c4665?w=1200"),
        .init(id: "destination-gabala", city: "Qəbələ", listingCount: 10, counts: .init(stay: 4, tour: 2, activity: 3, experience: 1), coverImage: "https://images.unsplash.com/photo-1470770841072-f978cf4d019e?w=1200")
    ]

    static let amenities: [AmenityModel] = [
        .init(id: "wifi", name: "Wi-Fi", description: nil, icon: "wifi", isDeleted: false, listingTypes: [.stay]),
        .init(id: "parking", name: "Pulsuz parkinq", description: nil, icon: "car", isDeleted: false, listingTypes: [.stay]),
        .init(id: "guide", name: "Bələdçi", description: nil, icon: "person.fill.questionmark", isDeleted: false, listingTypes: [.tour, .experience]),
        .init(id: "transfer", name: "Transfer", description: nil, icon: "car.fill", isDeleted: false, listingTypes: [.tour, .activity])
    ]

    static let listings: [PublicListing] = [
        .init(id: "listing-sheki-house", type: .stay, title: "Şəkidə tarixi həyət evi", slug: "sheki-historic-courtyard", shortDescription: "Köhnə şəhərin yaxınlığında sakit və rahat istirahət", basePrice: 145, currency: "AZN", isFeatured: true, category: category("culture"), location: location("Şəki", 41.1919, 47.1706), coverMedia: cover("photo-1600607687939-ce8a6c25118c"), rating: .init(average: 4.9, count: 86), details: .stay(.init(maxGuests: 4))),
        .init(id: "listing-baku-walk", type: .tour, title: "Bakının İçərişəhər gəzintisi", slug: "baku-old-city-walk", shortDescription: "İçərişəhərin hekayələrini yerli bələdçi ilə kəşf et", basePrice: 35, currency: "AZN", isFeatured: true, category: category("culture"), location: location("Bakı", 40.3661, 49.8371), coverMedia: cover("photo-1518005020951-eccb494ad742"), rating: .init(average: 4.8, count: 124), details: .tour(.init(durationMinutes: 150))),
        .init(id: "listing-gabala-hike", type: .activity, title: "Qəbələdə dağ cığırı yürüşü", slug: "gabala-mountain-hike", shortDescription: "Meşə yolları və dağ mənzərələri ilə aktiv gün", basePrice: 55, currency: "AZN", category: category("nature"), location: location("Qəbələ", 40.9814, 47.8458), coverMedia: cover("photo-1551632811-561732d1e306"), rating: .init(average: 4.7, count: 58), details: .activity(.init(durationMinutes: 240))),
        .init(id: "listing-baku-food", type: .experience, title: "Bakı mətbəxindən dadım turu", slug: "baku-local-food-tasting", shortDescription: "Yerli bazar, ənənəvi yeməklər və çay süfrəsi", basePrice: 70, currency: "AZN", isFeatured: true, category: category("food"), location: location("Bakı", 40.3777, 49.8920), coverMedia: cover("photo-1555939594-58d7cb561ad1"), rating: .init(average: 5.0, count: 41), details: .experience),
        .init(id: "listing-qusar-cabin", type: .stay, title: "Qusarda meşə kənarı dağ evi", slug: "qusar-forest-cabin", shortDescription: "Təbiət qoynunda ailəvi həftəsonu", basePrice: 190, currency: "AZN", category: category("nature"), location: location("Qusar", 41.4275, 48.4302), coverMedia: cover("photo-1449158743715-0a90ebb6d2d8"), rating: .init(average: 4.8, count: 63), details: .stay(.init(maxGuests: 6))),
        .init(id: "listing-sheki-cooking", type: .experience, title: "Şəkidə paxlava ustad dərsi", slug: "sheki-pakhlava-workshop", shortDescription: "Şəki paxlavasını yerli usta ilə hazırlamağı öyrən", basePrice: 45, currency: "AZN", category: category("food"), location: location("Şəki", 41.2010, 47.1780), coverMedia: cover("photo-1556911220-e15b29be8c8f"), rating: .init(average: 4.9, count: 29), details: .experience),
        .init(id: "listing-baku-sea", type: .activity, title: "Bakı sahilində qayıq gəzintisi", slug: "baku-waterfront-boat-trip", shortDescription: "Xəzər sahilindən şəhərin mənzərəsinə bax", basePrice: 60, currency: "AZN", category: category("nature"), location: location("Bakı", 40.3500, 49.8400), coverMedia: cover("photo-1500375592092-40eb2168fd21"), rating: .init(average: 4.6, count: 37), details: .activity(.init(durationMinutes: 90))),
        .init(id: "listing-gabala-guide", type: .tour, title: "Qəbələ və Nohur gölü turu", slug: "gabala-nohur-lake-tour", shortDescription: "Qəbələnin seçilən təbiət məkanlarına birgünlük tur", basePrice: 85, currency: "AZN", category: category("nature"), location: location("Qəbələ", 40.9890, 47.8670), coverMedia: cover("photo-1500530855697-b586d89ba3ee"), rating: .init(average: 4.8, count: 72), details: .tour(.init(durationMinutes: 360)))
    ]

    static let details: [String: Listing] = [
        "sheki-historic-courtyard": detail(from: listings[0], description: "Şəkinin tarixi mərkəzində yerləşən bu rahat həyət evi şəhəri piyada kəşf etmək üçün ideal başlanğıc nöqtəsidir. Geniş otaqlar, sakit həyət və yerli qonaqpərvərlik sizi gözləyir.", details: .stay(.init(propertyType: "house", maxGuests: 4, bedrooms: 2, beds: 3, bathrooms: 1, checkInFrom: "14:00", checkOutUntil: "12:00", minimumNights: 1, instantBooking: true)), amenities: [amenities[0], amenities[1]]),
        "baku-old-city-walk": detail(from: listings[1], description: "Yerli bələdçi ilə İçərişəhərin dar küçələrini, qədim karvansaraları və şəhərin ən maraqlı guşələrini kəşf edin. Gəzinti rahat tempdə keçirilir.", details: .tour(.init(durationMinutes: 150, maxParticipants: 8, minimumAge: 6, meetingPoint: "Qoşa Qala qapısı", languages: ["az", "en"], isPrivateTour: false)), amenities: [amenities[2]]),
        "gabala-mountain-hike": detail(from: listings[2], description: "Qəbələnin yaşıl meşələri və dağ mənzərələri boyunca bələdçili yürüş. Marşrut hava şəraitinə uyğun seçilir və fasilələrlə keçirilir.", details: .activity(.init(durationMinutes: 240, maxParticipants: 10, minimumAge: 12, difficulty: "moderate", equipmentProvided: true)), amenities: [amenities[2], amenities[3]]),
        "baku-local-food-tasting": detail(from: listings[3], description: "Bakı bazarının rənglərini, ənənəvi Azərbaycan yeməklərini və yerli çay süfrəsini bir təcrübədə birləşdirin. Dadım turu kiçik qruplar üçün nəzərdə tutulub.", details: .experience(.init(durationMinutes: 210, maxParticipants: 6, minimumAge: 8, hostIncluded: true, isPrivate: false)), amenities: [amenities[2]]),
        "qusar-forest-cabin": detail(from: listings[4], description: "Meşə kənarındakı dağ evi təmiz hava və sakitlik axtaran qonaqlar üçün uyğundur. Yaxınlıqda gəzinti cığırları və mənzərəli istirahət yerləri var.", details: .stay(.init(propertyType: "cabin", maxGuests: 6, bedrooms: 3, beds: 4, bathrooms: 2, checkInFrom: "15:00", checkOutUntil: "11:00", minimumNights: 2, instantBooking: true)), amenities: [amenities[0], amenities[1]])
    ]

    static func detail(for slug: String) -> Listing? { details[slug] }

    private static func category(_ id: String) -> ListingCategory {
        guard let category = categories.first(where: { $0.slug == id }) else {
            return ListingCategory(id: id, name: "", slug: id)
        }
        return ListingCategory(id: category.id, name: category.name, slug: category.slug)
    }

    private static func location(_ city: String, _ latitude: Double, _ longitude: Double) -> ListingLocation {
        ListingLocation(countryCode: "AZ", city: city, latitude: latitude, longitude: longitude)
    }

    private static func cover(_ photo: String) -> CoverMedia {
        CoverMedia(type: .image, url: "https://images.unsplash.com/\(photo)?auto=format&fit=crop&w=1400&q=85")
    }

    private static func detail(from listing: PublicListing, description: String, details: ListingDetails, amenities: [AmenityModel]) -> Listing {
        Listing(
            id: listing.id,
            type: listing.type,
            category: categories.first { $0.id == listing.category?.id },
            location: listing.location,
            basePrice: listing.basePrice,
            currency: listing.currency,
            status: .published,
            title: listing.title,
            slug: listing.slug,
            shortDescription: listing.shortDescription,
            description: description,
            media: [ListingMedia(id: "\(listing.id)-cover", type: "image", url: listing.coverMedia?.url ?? "", isCover: true, order: 0)],
            amenities: amenities,
            details: details,
            rating: listing.rating,
            isFavorite: listing.isFavorite
        )
    }
}

@MainActor
final class MockTravelService: ListingServicesProtocol, ListingDetailServiceProtocol, CategoryServicesProtocol, DiscoveryServicesProtocol {
    func getListings(query: ListingQuery) async throws -> [ListingResponse] {
        filter(query: query).prefix(max(1, query.limit)).map { $0 }
    }

    func searchListings(criteria: ListingSearchCriteria) async throws -> ListingsPage {
        let matching = filter(query: criteria)
        let limit = max(1, criteria.limit)
        let start = max(0, criteria.page - 1) * limit
        let page = start < matching.count ? Array(matching.dropFirst(start).prefix(limit)) : []
        let pages = max(1, Int(ceil(Double(matching.count) / Double(limit))))
        return ListingsPage(listings: page, meta: PaginationMeta(page: criteria.page, limit: limit, total: matching.count, totalPages: pages))
    }

    func getListing(slug: String, locale: String, includeCustomerToken: Bool) async throws -> Listing {
        guard let listing = MockTravelData.detail(for: slug) else { throw NetworkError.listingNotFound }
        return listing
    }

    func getCategories() async throws -> [CategoryModel] { MockTravelData.categories }
    func getCategories(type: ListingType?, locale: String) async throws -> [CategoryModel] { MockTravelData.categories }
    func getAmenities(type: ListingType?, locale: String) async throws -> [AmenityModel] {
        guard let type else { return MockTravelData.amenities }
        return MockTravelData.amenities.filter { $0.listingTypes.contains(type) }
    }
    func getCities() async throws -> [ListingCity] { MockTravelData.cities }
    func getPopularDestinations() async throws -> [PopularDestination] { MockTravelData.destinations }

    private func filter(query: ListingSearchCriteria) -> [PublicListing] {
        var result = MockTravelData.listings.filter { listing in
            if let type = query.type, listing.type != type { return false }
            if let categoryId = query.categoryId, listing.category?.id != categoryId { return false }
            if let city = query.city,
               listing.location?.city?.localizedCaseInsensitiveContains(city) != true { return false }
            if let destination = query.destinationName,
               listing.location?.city?.localizedCaseInsensitiveContains(destination) != true { return false }
            if let minPrice = query.minPrice, listing.basePrice < minPrice { return false }
            if let maxPrice = query.maxPrice, listing.basePrice > maxPrice { return false }
            if let minRating = query.minRating,
               (listing.rating.average ?? 0) < Double(minRating) { return false }
            if !query.query.isEmpty {
                let cityMatches = listing.location?.city?.localizedCaseInsensitiveContains(query.query) ?? false
                let descriptionMatches = listing.shortDescription?.localizedCaseInsensitiveContains(query.query) ?? false
                guard listing.title.localizedCaseInsensitiveContains(query.query)
                        || descriptionMatches || cityMatches else { return false }
            }
            return true
        }
        switch query.sort {
        case .newest: break
        case .featured: result.sort { $0.isFeatured && !$1.isFeatured }
        case .priceAscending: result.sort { $0.basePrice < $1.basePrice }
        case .priceDescending: result.sort { $0.basePrice > $1.basePrice }
        case .ratingDescending: result.sort { ($0.rating.average ?? 0) > ($1.rating.average ?? 0) }
        }
        return result
    }
}
