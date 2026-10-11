import SwiftUI

struct TravelPlannerInputPanel: View {
    let s: PlannerSession
    @Bindable var model: TravelPlannerViewModel
    var budgetFocused: FocusState<Bool>.Binding
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch s.input.type {
            case "single_select":
                ForEach(s.input.options ?? []) { option in
                    Button {
                        Task { await model.selectDestination(option.value) }
                    } label: {
                        HStack {
                            Text(option.label)
                            Spacer()
                            if model.cityId == option.value {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding(12).background(
                            Color.surfaceBg,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }.buttonStyle(.plain)
                }
            case "date_range":
                DatePicker(
                    "planner.checkIn",
                    selection: $model.checkIn,
                    displayedComponents: .date
                )
                DatePicker(
                    "planner.checkOut",
                    selection: $model.checkOut,
                    displayedComponents: .date
                )
            case "guests":
                Stepper(
                    "\(String(localized: "planner.adults")): \(model.adults)",
                    value: $model.adults,
                    in: model.adultRange
                )
                Stepper(
                    "\(String(localized: "planner.children")): \(model.children)",
                    value: $model.children,
                    in: model.childrenRange
                )
            case "money":
                HStack {
                    TextField("planner.amount", text: $model.amount)
                        .keyboardType(.decimalPad).textFieldStyle(
                            .roundedBorder
                        ).focused(budgetFocused)
                    Text("AZN").font(.headline)
                }
            case "multi_select":
                ForEach(s.input.options ?? []) { option in
                    Button {
                        model.toggleInterest(option.value)
                    } label: {
                        let selected =
                            option.value.map { model.interests.contains($0) }
                            ?? model.interests.isEmpty
                        Label(
                            option.label,
                            systemImage: selected
                                ? "checkmark.circle.fill" : "circle"
                        )
                        .padding(12).frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(
                            Color.surfaceBg,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }.buttonStyle(.plain)
                }
            case "confirmation":
                ForEach(Array(model.bubbles.enumerated()), id: \.offset) {
                    _,
                    text in Text(text)
                }
            default: EmptyView()
            }
            ForEach(model.fieldErrors.keys.sorted(), id: \.self) { field in
                Text("\(field): \(model.fieldErrors[field] ?? "")").font(
                    .footnote
                ).foregroundStyle(.red)
            }
        }
        .environment(\.timeZone, PlannerValues.calendar.timeZone)
        .environment(\.calendar, PlannerValues.calendar)
        .disabled(model.isLoading)
    }

}
