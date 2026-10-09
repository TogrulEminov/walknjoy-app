import SwiftUI

struct SearchFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ListingSearchCriteria
    @State private var minPrice: String
    @State private var maxPrice: String
    let categories: [CategoryModel]
    let amenities: [AmenityModel]
    let onApply: (ListingSearchCriteria) -> Void

    init(
        criteria: ListingSearchCriteria,
        categories: [CategoryModel],
        amenities: [AmenityModel],
        onApply: @escaping (ListingSearchCriteria) -> Void
    ) {
        _draft = State(initialValue: criteria)
        _minPrice = State(
            initialValue: criteria.minPrice.map {
                NSDecimalNumber(decimal: $0).stringValue
            } ?? ""
        )
        _maxPrice = State(
            initialValue: criteria.maxPrice.map {
                NSDecimalNumber(decimal: $0).stringValue
            } ?? ""
        )
        self.categories = categories
        self.amenities = amenities
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("search.filter.price") {
                    TextField("search.filter.minPrice", text: $minPrice)
                        .keyboardType(.decimalPad)
                    TextField("search.filter.maxPrice", text: $maxPrice)
                        .keyboardType(.decimalPad)
                    if let validationError {
                        Text(validationError).foregroundStyle(Color.errorC)
                    }
                }
                .listRowBackground(Color.surfaceBackground)

                Section("search.filter.general") {
                    optionLink(
                        "search.filter.rating",
                        options: ratingOptions,
                        selection: $draft.minRating
                    )
                    optionLink(
                        "search.filter.category",
                        options: categoryOptions,
                        selection: $draft.categoryId
                    )
                    optionLink(
                        "search.sort",
                        options: sortOptions,
                        selection: $draft.sort
                    )
                }
                .listRowBackground(Color.surfaceBackground)

                if draft.type == .stay {
                    Section("listing.type.stay") {
                        optionLink(
                            "search.filter.propertyType",
                            options: propertyTypeOptions,
                            selection: $draft.propertyType
                        )
                        FilterDateRange(
                            start: $draft.checkIn,
                            end: $draft.checkOut
                        )
                        Stepper(value: $draft.adults, in: 1...99) {
                            Text(
                                String(
                                    format: String(
                                        localized: "home.search.adultsFormat"
                                    ),
                                    draft.adults
                                )
                            )
                        }
                        Stepper(value: $draft.children, in: 0...99) {
                            Text(
                                String(
                                    format: String(
                                        localized: "home.search.childrenFormat"
                                    ),
                                    draft.children
                                )
                            )
                        }
                    }
                    .listRowBackground(Color.surfaceBackground)
                } else if draft.type != nil {
                    Section("search.filter.schedule") {
                        FilterDateRange(
                            start: $draft.dateFrom,
                            end: $draft.dateTo
                        )
                        Stepper(value: $draft.participants, in: 1...99) {
                            Text(
                                String(
                                    format: String(
                                        localized:
                                            "home.search.participantsFormat"
                                    ),
                                    draft.participants
                                )
                            )
                        }
                    }
                    .listRowBackground(Color.surfaceBackground)
                }

                if !amenities.isEmpty {
                    Section("search.filter.amenities") {
                        ForEach(amenities) { amenity in
                            Toggle(
                                amenity.name,
                                isOn: amenityBinding(amenity.id)
                            )
                        }
                    }
                    .listRowBackground(Color.surfaceBackground)
                }
            }
            .foregroundStyle(Color.titleText)
            .tint(Color.buttonBackground)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("search.filter.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.apply") { apply() }
                        .disabled(validationError != nil)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("common.reset", role: .destructive) { reset() }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.appBackground)
            }
        }
    }

    // MARK: - Option rows

    private func optionLink<Value: Hashable>(
        _ title: LocalizedStringKey,
        options: [OptionListView<Value>.Option],
        selection: Binding<Value>
    ) -> some View {
        NavigationLink {
            OptionListView(title: title, options: options, selection: selection)
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(
                    options.first { $0.value == selection.wrappedValue }?.title
                        ?? ""
                )
                .foregroundStyle(Color.description)
                .lineLimit(1)
            }
        }
    }

    private var anyTitle: String { String(localized: "search.filter.any") }

    private var ratingOptions: [OptionListView<Int?>.Option] {
        [.init(title: anyTitle, value: nil)]
            + (1...5).map { .init(title: "\($0)+", value: Optional($0)) }
    }

    private var categoryOptions: [OptionListView<String?>.Option] {
        [.init(title: anyTitle, value: nil)]
            + categories.map { .init(title: $0.name, value: Optional($0.id)) }
    }

    private var propertyTypeOptions: [OptionListView<String?>.Option] {
        [.init(title: anyTitle, value: nil)]
            + PropertyType.allCases.map {
                .init(title: $0.title, value: Optional($0.rawValue))
            }
    }

    private var sortOptions: [OptionListView<ListingSort>.Option] {
        ListingSort.allCases.map { .init(title: $0.titleString, value: $0) }
    }

    // MARK: - Logic

    private var validationError: LocalizedStringKey? {
        if let min = Decimal(string: minPrice),
            let max = Decimal(string: maxPrice), min > max
        {
            return "search.validation.price"
        }
        if let start = draft.checkIn, let end = draft.checkOut, start >= end {
            return "search.validation.stayDates"
        }
        if let start = draft.dateFrom, let end = draft.dateTo, start >= end {
            return "search.validation.dates"
        }
        return nil
    }

    private func apply() {
        draft.minPrice = Decimal(string: minPrice)
        draft.maxPrice = Decimal(string: maxPrice)
        draft.page = 1
        onApply(draft)
        dismiss()
    }

    private func reset() {
        draft.resetFilters()
        minPrice = ""
        maxPrice = ""
    }

    private func amenityBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { draft.amenityIds.contains(id) },
            set: { selected in
                if selected {
                    draft.amenityIds.insert(id)
                } else {
                    draft.amenityIds.remove(id)
                }
            }
        )
    }
}

// MARK: - Date range (iki tarix bərabər enlidə, yan-yana)

private struct FilterDateRange: View {
    @Binding var start: Date?
    @Binding var end: Date?

    private var enabled: Binding<Bool> {
        Binding(
            get: { start != nil || end != nil },
            set: { isOn in
                if isOn {
                    let today = Calendar.current.startOfDay(for: Date())
                    start = today
                    end =
                        Calendar.current.date(
                            byAdding: .day,
                            value: 1,
                            to: today
                        ) ?? today
                } else {
                    start = nil
                    end = nil
                }
            }
        )
    }

    var body: some View {
        Toggle("home.search.chooseDates", isOn: enabled)

        if enabled.wrappedValue {
            HStack(alignment: .top, spacing: 12) {
                dateField("search.date.from", selection: binding($start))
                dateField("search.date.to", selection: binding($end))
            }
        }
    }

    private func dateField(
        _ title: LocalizedStringKey,
        selection: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.description)
            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func binding(_ value: Binding<Date?>) -> Binding<Date> {
        Binding(
            get: { value.wrappedValue ?? Date() },
            set: { value.wrappedValue = $0 }
        )
    }
}

// MARK: - ListingSort

extension ListingSort {
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .newest: "search.sort.newest"
        case .priceAscending: "search.sort.priceAsc"
        case .priceDescending: "search.sort.priceDesc"
        case .featured: "search.sort.featured"
        case .ratingDescending: "search.sort.rating"
        }
    }

    var titleString: String {
        switch self {
        case .newest: String(localized: "search.sort.newest")
        case .priceAscending: String(localized: "search.sort.priceAsc")
        case .priceDescending: String(localized: "search.sort.priceDesc")
        case .featured: String(localized: "search.sort.featured")
        case .ratingDescending: String(localized: "search.sort.rating")
        }
    }
}

// Public listing filters share the existing search filter implementation.
typealias ListingFilterView = SearchFilterView
