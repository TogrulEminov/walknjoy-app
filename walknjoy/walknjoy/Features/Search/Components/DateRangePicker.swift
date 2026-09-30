import SwiftUI

struct DateRangePicker: View {
    @Binding var start: Date?
    @Binding var end: Date?

    var body: some View {
        HStack(spacing: 10) {
            datePicker("search.date.from", selection: $start)
            datePicker("search.date.to", selection: $end)
        }
    }

    private func datePicker(_ title: LocalizedStringKey, selection: Binding<Date?>) -> some View {
        DatePicker(
            title,
            selection: Binding(
                get: { selection.wrappedValue ?? Date() },
                set: { selection.wrappedValue = $0 }
            ),
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityLabel(title)
    }
}
