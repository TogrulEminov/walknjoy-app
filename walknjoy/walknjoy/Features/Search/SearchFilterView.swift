import SwiftUI

struct SearchFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: SearchFilterViewModel
    let categories: [CategoryModel]
    let amenities: [AmenityModel]
    let onApply: (ListingSearchCriteria) -> Void

    init(
        criteria: ListingSearchCriteria,
        categories: [CategoryModel],
        amenities: [AmenityModel],
        onApply: @escaping (ListingSearchCriteria) -> Void
    ) {
        _model = State(initialValue: SearchFilterViewModel(criteria: criteria))
        self.categories = categories
        self.amenities = amenities
        self.onApply = onApply
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("search.filter.price") {
                    TextField("search.filter.minPrice", text: $model.minPrice)
                        .keyboardType(.decimalPad)
                    TextField("search.filter.maxPrice", text: $model.maxPrice)
                        .keyboardType(.decimalPad)
                    if let key = model.validationErrorKey {
                        Text(LocalizedStringKey(key)).foregroundStyle(
                            Color.errorC
                        )
                    }
                }
                .listRowBackground(Color.surfaceBackground)

                Section("search.filter.general") {
                    optionLink(
                        "search.filter.rating",
                        options: ratingOptions,
                        selection: $model.draft.minRating
                    )
                    optionLink(
                        "search.filter.category",
                        options: categoryOptions,
                        selection: $model.draft.categoryId
                    )
                    optionLink(
                        "search.sort",
                        options: sortOptions,
                        selection: $model.draft.sort
                    )
                }
                .listRowBackground(Color.surfaceBackground)

                if model.draft.type == .stay {
                    Section("listing.type.stay") {
                        optionLink(
                            "search.filter.propertyType",
                            options: propertyTypeOptions,
                            selection: $model.draft.propertyType
                        )
                        FilterDateRange(
                            start: $model.draft.checkIn,
                            end: $model.draft.checkOut
                        )
                        Stepper(value: $model.draft.adults, in: 1...99) {
                            Text(
                                String(
                                    format: String(
                                        localized: "home.search.adultsFormat"
                                    ),
                                    model.draft.adults
                                )
                            )
                        }
                        Stepper(value: $model.draft.children, in: 0...99) {
                            Text(
                                String(
                                    format: String(
                                        localized: "home.search.childrenFormat"
                                    ),
                                    model.draft.children
                                )
                            )
                        }
                    }
                    .listRowBackground(Color.surfaceBackground)
                } else if model.draft.type != nil {
                    Section("search.filter.schedule") {
                        FilterDateRange(
                            start: $model.draft.dateFrom,
                            end: $model.draft.dateTo
                        )
                        Stepper(value: $model.draft.participants, in: 1...99) {
                            Text(
                                String(
                                    format: String(
                                        localized:
                                            "home.search.participantsFormat"
                                    ),
                                    model.draft.participants
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
                    Button("common.apply") {
                        onApply(model.criteriaForSubmission())
                        dismiss()
                    }
                    .disabled(model.validationErrorKey != nil)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("common.reset", role: .destructive) { model.reset() }
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

    private func amenityBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { model.draft.amenityIds.contains(id) },
            set: { selected in
                model.setAmenity(id, selected: selected)
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
 
typealias ListingFilterView = SearchFilterView
