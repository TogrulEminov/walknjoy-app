import Foundation

struct ProviderProfile: Decodable, Equatable {
    let id: String
    let userId: String
    let businessName: String
    let legalName: String?
    let description: String?
    let phone: String?
    let email: String?
    let website: String?
    let logoUrl: String?
    let taxId: String?
    let status: ProviderStatus
    let verifiedAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct ProviderApplicationResponseData: Decodable {
    let profile: ProviderProfile
    let accessToken: String
}

struct ProviderApplicationInput: Encodable {
    let businessName: String
    let legalName: String?
    let description: String?
    let phone: String?
    let email: String?
    let website: String?
    let taxId: String?
}

struct UpdateProviderProfileInput: Encodable {
    let businessName: String?
    let legalName: String??
    let description: String??
    let phone: String??
    let email: String??
    let website: String??
    let logoUrl: String??
    let taxId: String??

    enum CodingKeys: String, CodingKey {
        case businessName, legalName, description, phone, email, website,
            logoUrl, taxId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(businessName, forKey: .businessName)
        try encode(legalName, forKey: .legalName, into: &container)
        try encode(description, forKey: .description, into: &container)
        try encode(phone, forKey: .phone, into: &container)
        try encode(email, forKey: .email, into: &container)
        try encode(website, forKey: .website, into: &container)
        try encode(logoUrl, forKey: .logoUrl, into: &container)
        try encode(taxId, forKey: .taxId, into: &container)
    }

    private func encode(
        _ value: String??,
        forKey key: CodingKeys,
        into container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
        guard let value else { return }
        if let value {
            try container.encode(value, forKey: key)
        } else {
            try container.encodeNil(forKey: key)
        }
    }
}
