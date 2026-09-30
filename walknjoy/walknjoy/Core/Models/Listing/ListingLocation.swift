import Foundation

struct ListingLocation: Codable, Equatable {
    var id: String? = nil
    var cityId: String? = nil
    var countryCode: String
    var city: String?
    var district: String? = nil
    var addressLine: String? = nil
    var latitude: Double?
    var longitude: Double?
}

struct ListingCity: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let latitude: Double?
    let longitude: Double?
}
