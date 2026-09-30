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
        _minPrice = State(initialValue: criteria.minPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
        _maxPrice = State(initialValue: criteria.maxPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
        self.categories = categories
        self.amenities = amenities
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("search.filter.price") {
                    TextField("search.filter.minPrice", text: $minPrice).keyboardType(.decimalPad)
                    TextField("search.filter.maxPrice", text: $maxPrice).keyboardType(.decimalPad)
                    if let validationError { Text(validationError).foregroundStyle(Color.errorC) }
                }
                .listRowBackground(Color.surfaceBackground)

                Section("search.filter.general") {
                    Picker("search.filter.rating", selection: $draft.minRating) {
                        Text("search.filter.any").tag(Int?.none)
                        ForEach(1...5, id: \.self) { Text(verbatim: "\($0)+").tag(Optional($0)) }
                    }
                    Picker("search.filter.category", selection: $draft.categoryId) {
                        Text("search.filter.any").tag(String?.none)
                        ForEach(categories) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Picker("search.sort", selection: $draft.sort) {
                        ForEach(ListingSort.allCases) { Text($0.localizedTitle).tag($0) }
                    }
                }
                .listRowBackground(Color.surfaceBackground)

                if draft.type == .stay {
                    Section("listing.type.stay") {
                        Picker("search.filter.propertyType", selection: $draft.propertyType) {
                            Text("search.filter.any").tag(String?.none)
                            ForEach(PropertyType.allCases, id: \.rawValue) { type in
                                Text(type.title)
                                    .tag(Optional(type.rawValue))
                            }
                        }
                        .pickerStyle(.menu)
                        DateRangePicker(start: $draft.checkIn, end: $draft.checkOut)
                        GuestPicker(adults: $draft.adults, children: $draft.children)
                    }
                    .listRowBackground(Color.surfaceBackground)
                } else if draft.type != nil {
                    Section("search.filter.schedule") {
                        DateRangePicker(start: $draft.dateFrom, end: $draft.dateTo)
                        Stepper("\(String(localized: "search.participants")): \(draft.participants)", value: $draft.participants, in: 1...99)
                    }
                    .listRowBackground(Color.surfaceBackground)
                }

                if !amenities.isEmpty {
                    Section("search.filter.amenities") {
                        ForEach(amenities) { amenity in
                            Toggle(amenity.name, isOn: amenityBinding(amenity.id))
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
                    Button("common.apply") { apply() }.disabled(validationError != nil)
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

    private var validationError: LocalizedStringKey? {
        if let min = Decimal(string: minPrice), let max = Decimal(string: maxPrice), min > max {
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
                if selected { draft.amenityIds.insert(id) }
                else { draft.amenityIds.remove(id) }
            }
        )
    }


}

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
}

// Public listing filters share the existing search filter implementation.
typealias ListingFilterView = SearchFilterView
