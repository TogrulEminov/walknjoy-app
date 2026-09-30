import SwiftUI

struct GuestPicker: View {
    @Binding var adults: Int
    @Binding var children: Int

    var body: some View {
        HStack(spacing: 16) {
            Stepper("\(String(localized: "search.adults")): \(adults)", value: $adults, in: 1...99)
            Divider().frame(height: 28)
            Stepper("\(String(localized: "search.children")): \(children)", value: $children, in: 0...99)
        }
        .font(.subheadline)
        .frame(minHeight: 44)
    }
}
