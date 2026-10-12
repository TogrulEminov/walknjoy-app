import Foundation

struct ConversationContext: Decodable {
    struct ListingInfo: Decodable {
        let id: String
        let title: String?
        let slug: String?
        let coverMedia: CoverMedia?
    }
    let type: String
    let listing: ListingInfo?
    let bookingId: String?
}
struct ConversationParticipant: Decodable, Identifiable {
    let id: String
    let displayName: String
    let avatarFile: UploadedFile?
}
struct ConversationDetail: Decodable, Identifiable {
    let id: String
    let context: ConversationContext
    let participants: [ConversationParticipant]
    let unreadCount: Int
    let createdAt: String
    let updatedAt: String
    func otherParticipant(userID: String) -> ConversationParticipant? {
        participants.first { $0.id != userID }
    }
}
struct ConversationRow: Decodable, Identifiable {
    struct Preview: Decodable {
        let id: String
        let content: String
        let senderId: String
        let createdAt: String
    }
    let id: String
    let context: ConversationContext
    let otherParticipant: ConversationParticipant
    let lastMessage: Preview?
    let unreadCount: Int
    let updatedAt: String
}
struct ChatMessage: Decodable, Identifiable, Equatable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let createdAt: String
}
struct MessagePage: Decodable {
    struct Meta: Decodable { let nextCursor: String? }
    let success: Bool
    let data: [ChatMessage]
    let meta: Meta
}
struct ConversationPage {
    let items: [ConversationRow]
    let meta: PaginationMeta
}
struct ChatReadReceipt: Decodable {
    let conversationId: String
    let userId: String
    let lastReadMessageId: String?
    let readAt: String
}
struct ChatReadResponse: Decodable {
    let success: Bool
    let data: ChatReadReceipt?
}
enum ConversationStart {
    case listing(String)
    case booking(String)
    case providerBooking(String)
}
struct OutgoingMessage: Identifiable {
    enum Status { case pending, failed }
    let id: String
    let content: String
    let createdAt: String
    var status: Status
}
enum ChatFormatting {
    static func date(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        return formatter.date(from: text)
            ?? ISO8601DateFormatter().date(from: text)
    }
    static func merge(_ existing: [ChatMessage], _ incoming: [ChatMessage])
        -> [ChatMessage]
    {
        var byID = Dictionary(
            existing.map { ($0.id, $0) },
            uniquingKeysWith: { _, last in last }
        )
        for message in incoming { byID[message.id] = message }
        return byID.values.sorted {
            let left = date($0.createdAt)
            let right = date($1.createdAt)
            if let left, let right {
                return left == right ? $0.id < $1.id : left < right
            }
            return $0.createdAt == $1.createdAt
                ? $0.id < $1.id : $0.createdAt < $1.createdAt
        }
    }
}
