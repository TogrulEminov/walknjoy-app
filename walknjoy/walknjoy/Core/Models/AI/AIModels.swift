import Foundation

struct AISuggestion: Decodable, Identifiable {
    let id: String
    let title: String
    let prompt: String
    let type: String?
    let categoryId: String?
    let city: String?

    var listingType: ListingType? {
        type.flatMap { ListingType(rawValue: $0.lowercased()) }
    }
}

struct AISuggestions: Decodable {
    let suggestions: [AISuggestion]
    let general: [AISuggestion]
}

struct AIConversationSummary: Decodable, Identifiable {
    let id: String
    let title: String?
    let updatedAt: Date
    let lastMessage: String?
    let messageCount: Int
}

struct AIConversation: Decodable, Identifiable {
    let id: String
    let title: String?
    let createdAt: Date
    let updatedAt: Date
    let messages: [AIMessage]
    let messagesTotal: Int
}

struct AIMessage: Decodable, Identifiable {
    let id: String
    let role: AIMessageRole
    let content: String
    let createdAt: Date
    let listings: [PublicListing]

    init(
        id: String,
        role: AIMessageRole,
        content: String,
        createdAt: Date,
        listings: [PublicListing] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.listings = listings
    }

    private enum CodingKeys: String, CodingKey {
        case id, role, content, createdAt, listings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(AIMessageRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        listings = try container.decodeIfPresent([PublicListing].self, forKey: .listings) ?? []
    }
}

enum AIMessageRole: String, Decodable {
    case user
    case assistant
}

struct AISentMessages: Decodable {
    let conversationId: String
    let userMessage: AIMessage
    let assistantMessage: AIMessage
}

struct AICreateConversation: Encodable {
    let title: String?
}

struct AISendMessage: Encodable {
    let message: String
    var context: AIMessageContext?
}

struct AIMessageContext: Encodable {
    let checkIn: String?
    let checkOut: String?
}

struct AIDeletedConversation: Decodable {
    let deleted: Bool
}
