import SwiftUI
import UIKit

/// UIKit's native calendar supports disabling individual dates through its delegate.
struct StayAvailabilityCalendar: UIViewRepresentable {
    let selectedDate: Date
    let canSelect: (Date) -> Bool
    let onSelect: (Date) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Calendar.current
        view.locale = context.environment.locale
        view.fontDesign = .rounded
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = selection
        let components = view.calendar.dateComponents([.year, .month, .day], from: selectedDate)
        view.setVisibleDateComponents(components, animated: false)
        if canSelect(selectedDate) {
            selection.setSelected(components, animated: false)
        }
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
        var parent: StayAvailabilityCalendar
        init(parent: StayAvailabilityCalendar) { self.parent = parent }

        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           canSelectDate dateComponents: DateComponents?) -> Bool {
            guard let dateComponents, let date = Calendar.current.date(from: dateComponents)
            else { return false }
            return parent.canSelect(date)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents, let date = Calendar.current.date(from: dateComponents),
                  parent.canSelect(date) else { return }
            parent.onSelect(date)
        }
    }
}
