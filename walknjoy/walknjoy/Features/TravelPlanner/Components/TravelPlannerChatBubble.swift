import SwiftUI

struct TravelPlannerChatBubble: View {
    let text: String
    let user: Bool
    var body: some View {
        Text(text).font(.body)
            .foregroundStyle(user ? Color.white : Color.title)
            .padding(14)
            .background(
                user ? Color.icon : Color.surfaceBg,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .frame(maxWidth: .infinity, alignment: user ? .trailing : .leading)
    }

}
