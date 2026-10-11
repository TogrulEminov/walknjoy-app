import Foundation

struct ListingLocation: Codable, Hashable {
    var id: String? = nil
    var cityId: String? = nil
    var countryCode: String
    var city: String?
    var district: String? = nil
    var addressLine: String? = nil
    var latitude: Double?
    var longitude: Double?

    init(
        id: String? = nil,
        cityId: String? = nil,
        countryCode: String,
        city: String? = nil,
        district: String? = nil,
        addressLine: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.cityId = cityId
        self.countryCode = countryCode
        self.city = city
        self.district = district
        self.addressLine = addressLine
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct ListingCity: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let latitude: Double?
    let longitude: Double?
}
