import SwiftUI

struct HomeSearchView: View {
    @Binding var criteria: ListingSearchCriteria
    let cities: [ListingCity]
    var onImage = false
    let onSearch: () -> Void
    @State private var showSearch = false
    @State private var submittedDraft: ListingSearchCriteria?

    var body: some View {
        Button {
            showSearch = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(onImage ? Color.brandYellow : Color.icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        criteria.destinationName
                            ?? String(localized: "home.search.prompt")
                    )
                    .font(.headline)
                    .foregroundStyle(onImage ? Color.brandYellow : Color.title)
                    Text("home.search.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(
                            onImage
                                ? Color.white.opacity(0.85)
                                : Color.description
                        )
                }
                Spacer(minLength: 0)
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(onImage ? Color.brandYellow : Color.icon)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                onImage ? Color.clear : Color.surfaceBg,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(
                    onImage ? Color.brandYellow.opacity(0.45) : Color.border,
                    lineWidth: 1
                )
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .accessibilityHint("home.search.openHint")
        .sheet(
            isPresented: $showSearch,
            onDismiss: {
                guard let submittedDraft else { return }
                criteria = submittedDraft
                self.submittedDraft = nil
                onSearch()
            }
        ) {
            HomeSearchSheet(criteria: criteria, cities: cities) { draft in
                submittedDraft = draft
                showSearch = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.appBackground)
        }
    }
}

private struct HomeSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ListingSearchCriteria
    let cities: [ListingCity]
    let onSearch: (ListingSearchCriteria) -> Void

    init(
        criteria: ListingSearchCriteria,
        cities: [ListingCity],
        onSearch: @escaping (ListingSearchCriteria) -> Void
    ) {
        _draft = State(initialValue: criteria)
        self.cities = cities
        self.onSearch = onSearch
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("search.city.title") {
                    Picker(
                        "search.city.title",
                        selection: Binding(
                            get: { draft.city ?? "" },
                            set: { city in
                                draft.city = city.isEmpty ? nil : city
                                draft.destinationName = draft.city
                                draft.destinationId = nil
                                draft.countryCode = nil
                            }
                        )
                    ) {
                        Text("search.city.all").tag("")
                        ForEach(cities) { Text($0.name).tag($0.name) }
                    }
                }
                .listRowBackground(Color.surfaceBg)
                Section("search.type") {
                    Picker("search.type", selection: $draft.type) {
                        Text("search.type.all").tag(ListingType?.none)
                        ForEach(ListingType.allCases) {
                            Text($0.title).tag(Optional($0))
                        }
                    }
                }
                .listRowBackground(Color.surfaceBg)
                if let type = draft.type {
                    Section("search.filter.schedule") {
                        Toggle("home.search.chooseDates", isOn: datesEnabled)
                        if datesEnabled.wrappedValue {
                            DatePicker(
                                "search.date.from",
                                selection: startDate,
                                displayedComponents: .date
                            )
                            DatePicker(
                                "search.date.to",
                                selection: endDate,
                                displayedComponents: .date
                            )
                        }
                        if let validationError {
                            Text(validationError).foregroundStyle(Color.errorC)
                        }
                    }
                    .listRowBackground(Color.surfaceBg)
                    if type == .stay {
                        Section("home.search.guests") {
                            Stepper(value: $draft.adults, in: 1...99) {
                                Text(String(format: String(localized: "home.search.adultsFormat"), draft.adults))
                            }
                            Stepper(value: $draft.children, in: 0...99) {
                                Text(String(format: String(localized: "home.search.childrenFormat"), draft.children))
                            }
                        }
                        .listRowBackground(Color.surfaceBg)
                    } else {
                        Section("search.participants") {
                            Stepper(value: $draft.participants, in: 1...99) {
                                Text(
                                    String(format: String(localized: "home.search.participantsFormat"), draft.participants)
                                )
                            }
                        }
                        .listRowBackground(Color.surfaceBg)
                    }
                }
            }
            .foregroundStyle(Color.title)
            .tint(Color.button)
            .scrollContentBackground(.hidden)
            .background(Color.appBg)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("search.action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    draft.page = 1
                    onSearch(draft)
                } label: {
                    Label("search.action", systemImage: "magnifyingglass")
                        .font(.headline)
                        .foregroundStyle(Color.buttonTxt)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            Color.button,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .buttonStyle(.plain)
                .disabled(validationError != nil)
                .opacity(validationError == nil ? 1 : 0.5)
                .padding(20)
                .background(Color.appBackground)
            }
            .onChange(of: draft.type) { _, _ in
                draft.categoryId = nil
                draft.amenityIds = []
            }
        }
    }

    private var datesEnabled: Binding<Bool> {
        Binding(
            get: {
                draft.type == .stay
                    ? draft.checkIn != nil : draft.dateFrom != nil
            },
            set: { enabled in
                let start = Calendar.current.startOfDay(for: Date())
                let end =
                    Calendar.current.date(byAdding: .day, value: 1, to: start)
                    ?? start
                if draft.type == .stay {
                    draft.checkIn = enabled ? start : nil
                    draft.checkOut = enabled ? end : nil
                } else {
                    draft.dateFrom = enabled ? start : nil
                    draft.dateTo = enabled ? end : nil
                }
            }
        )
    }
    private var startDate: Binding<Date> {
        Binding(
            get: {
                (draft.type == .stay ? draft.checkIn : draft.dateFrom) ?? Date()
            },
            set: {
                if draft.type == .stay {
                    draft.checkIn = $0
                } else {
                    draft.dateFrom = $0
                }
            }
        )
    }
    private var endDate: Binding<Date> {
        Binding(
            get: {
                (draft.type == .stay ? draft.checkOut : draft.dateTo) ?? Date()
            },
            set: {
                if draft.type == .stay {
                    draft.checkOut = $0
                } else {
                    draft.dateTo = $0
                }
            }
        )
    }
    private var validationError: LocalizedStringKey? {
        guard draft.type != nil, datesEnabled.wrappedValue else { return nil }
        if draft.type == .stay {
            return startDate.wrappedValue >= endDate.wrappedValue
                ? "search.validation.stayDates" : nil
        }
        return startDate.wrappedValue > endDate.wrappedValue
            ? "search.validation.dates" : nil
    }
}
