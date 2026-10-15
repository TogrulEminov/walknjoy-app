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
    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        return formatter
    }()
    private static let standardFormatter = ISO8601DateFormatter()

    static func date(_ text: String) -> Date? {
        fractionalFormatter.date(from: text)
            ?? standardFormatter.date(from: text)
    }
    static func merge(_ existing: [ChatMessage], _ incoming: [ChatMessage])
        -> [ChatMessage]
    {
        var byID = Dictionary(
            existing.map { ($0.id, $0) },
            uniquingKeysWith: { _, last in last }
        )
        for message in incoming { byID[message.id] = message }
        return byID.values.map { (message: $0, date: date($0.createdAt)) }
            .sorted {
                if let left = $0.date, let right = $1.date {
                    return left == right
                        ? $0.message.id < $1.message.id : left < right
                }
                return $0.message.createdAt == $1.message.createdAt
                    ? $0.message.id < $1.message.id
                    : $0.message.createdAt < $1.message.createdAt
            }
            .map(\.message)
    }
}
