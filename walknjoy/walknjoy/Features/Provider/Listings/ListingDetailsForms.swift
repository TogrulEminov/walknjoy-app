import SwiftUI

struct StayDetailsForm: View {
    @Binding var details: StayDetails
    var body: some View {
        Section("listing.stay.section") {
            Picker(
                "listing.stay.propertyType",
                selection: $details.propertyType
            ) {
                ForEach(PropertyType.allCases, id: \.rawValue) { type in
                    Text(type.title).tag(type.rawValue)
                }
                if PropertyType(rawValue: details.propertyType) == nil {
                    Text(details.propertyType).tag(details.propertyType)
                }
            }
            .pickerStyle(.menu)
            Stepper(
                String(
                    format: String(localized: "listing.guests.countFormat"),
                    details.maxGuests
                ),
                value: $details.maxGuests,
                in: 1...999
            )
            OptionalNumberField(
                title: "listing.stay.bedrooms",
                value: $details.bedrooms
            )
            OptionalNumberField(
                title: "listing.stay.beds",
                value: $details.beds
            )
            OptionalNumberField(
                title: "listing.stay.bathrooms",
                value: $details.bathrooms
            )
            OptionalNumberField(
                title: "listing.stay.minimumNights",
                value: $details.minimumNights
            )
            OptionalTimePicker(
                title: "listing.stay.checkInFrom",
                value: $details.checkInFrom
            )
            OptionalTimePicker(
                title: "listing.stay.checkInUntil",
                value: $details.checkInUntil
            )
            OptionalTimePicker(
                title: "listing.stay.checkOutFrom",
                value: $details.checkOutFrom
            )
            OptionalTimePicker(
                title: "listing.stay.checkOutUntil",
                value: $details.checkOutUntil
            )
            OptionalBoolPicker(
                title: "listing.stay.instantBooking",
                value: $details.instantBooking
            )
        }
    }
}

struct TourDetailsForm: View {
    @Binding var details: TourDetails
    var body: some View {
        Section("listing.tour.section") {
            OptionalNumberField(
                title: "listing.details.duration",
                value: $details.durationMinutes
            )
            OptionalNumberField(
                title: "listing.details.maxParticipants",
                value: $details.maxParticipants
            )
            OptionalNumberField(
                title: "listing.details.minimumAge",
                value: $details.minimumAge
            )
            BusinessInputField(
                "listing.tour.meetingPoint",
                text: text($details.meetingPoint)
            )
            BusinessInputField(
                "listing.tour.languages",
                text: Binding(
                    get: { details.languages.joined(separator: ", ") },
                    set: {
                        details.languages = $0.components(separatedBy: ",").map
                        { $0.trimmingCharacters(in: .whitespaces) }
                    }
                )
            )
            OptionalBoolPicker(
                title: "listing.tour.private",
                value: $details.isPrivateTour
            )
        }
    }
}

struct ActivityDetailsForm: View {
    @Binding var details: ActivityDetails
    var body: some View {
        Section("listing.activity.section") {
            OptionalNumberField(
                title: "listing.details.duration",
                value: $details.durationMinutes
            )
            OptionalNumberField(
                title: "listing.details.maxParticipants",
                value: $details.maxParticipants
            )
            OptionalNumberField(
                title: "listing.details.minimumAge",
                value: $details.minimumAge
            )
            Picker(
                "listing.activity.difficulty",
                selection: $details.difficulty
            ) {
                Text("common.notSelected").tag(String?.none)
                Text("listing.difficulty.easy").tag(Optional("easy"))
                Text("listing.difficulty.moderate").tag(Optional("moderate"))
                Text("listing.difficulty.hard").tag(Optional("hard"))
            }
            OptionalBoolPicker(
                title: "listing.activity.equipment",
                value: $details.equipmentProvided
            )
        }
    }
}

struct ExperienceDetailsForm: View {
    @Binding var details: ExperienceDetails
    var body: some View {
        Section("listing.experience.section") {
            OptionalNumberField(
                title: "listing.details.duration",
                value: $details.durationMinutes
            )
            OptionalNumberField(
                title: "listing.details.maxParticipants",
                value: $details.maxParticipants
            )
            OptionalNumberField(
                title: "listing.details.minimumAge",
                value: $details.minimumAge
            )
            OptionalBoolPicker(
                title: "listing.experience.hostIncluded",
                value: $details.hostIncluded
            )
            OptionalBoolPicker(
                title: "listing.experience.private",
                value: $details.isPrivate
            )
        }
    }
}

private struct OptionalTimePicker: View {
    let title: LocalizedStringKey
    @Binding var value: String?
    @State private var showingPicker = false
    @State private var selectedTime = Date()

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                selectedTime = value.flatMap { formatter.date(from: $0) }
                    ?? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                    ?? Date()
                showingPicker = true
            } label: {
                HStack {
                    Text(title).foregroundStyle(Color.titleText)
                    Spacer(minLength: 8)
                    if let value {
                        Text(verbatim: value).monospacedDigit()
                            .foregroundStyle(Color.titleText)
                    } else {
                        Text("common.select").foregroundStyle(Color.descriptionText)
                    }
                    Image(systemName: "clock").foregroundStyle(Color.iconColor)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if value != nil {
                Button {
                    value = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.descriptionText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common.reset"))
            }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                DatePicker(title, selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "az_AZ"))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("common.cancel") { showingPicker = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("common.apply") {
                                value = formatter.string(from: selectedTime)
                                showingPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.height(320)])
        }
    }
}

private struct OptionalNumberField: View {
    let title: LocalizedStringResource
    @Binding var value: Int?
    var body: some View {
        BusinessInputField(
            title,
            text: Binding(
                get: { value.map(String.init) ?? "" },
                set: { value = Int($0) }
            ),
            icon: "number",
            keyboard: .numberPad
        )
    }
}
private struct OptionalBoolPicker: View {
    let title: LocalizedStringKey
    @Binding var value: Bool?
    var body: some View {
        Picker(title, selection: $value) {
            Text("common.notSelected").tag(Bool?.none)
            Text("common.yes").tag(Optional(true))
            Text("common.no").tag(Optional(false))
        }
    }
}
private func text(_ value: Binding<String?>) -> Binding<String> {
    Binding(
        get: { value.wrappedValue ?? "" },
        set: { value.wrappedValue = $0.listingNonBlank }
    )
}

struct CategoryPickerView: View {
    let categories: [CategoryModel]
    @Binding var selection: String?
    var body: some View {
        Picker("listing.category", selection: $selection) {
            Text("common.select").tag(String?.none)
            ForEach(categories) { Text($0.name).tag(Optional($0.id)) }
        }
    }
}
struct AmenityPickerView: View {
    let amenities: [AmenityModel]
    @Binding var selection: Set<String>
    var body: some View {
        Section("listing.amenities") {
            ForEach(amenities) { amenity in
                Toggle(
                    amenity.name,
                    isOn: Binding(
                        get: { selection.contains(amenity.id) },
                        set: {
                            if $0 {
                                selection.insert(amenity.id)
                            } else {
                                selection.remove(amenity.id)
                            }
                        }
                    )
                )
            }
            if amenities.isEmpty {
                Text("listing.amenities.empty")
                    .foregroundStyle(Color.descriptionText)
            }
        }
    }
}
struct LocationPickerView: View {
    let cities: [ListingCity]
    @Binding var cityId: String
    @Binding var latitude: String
    @Binding var longitude: String
    @Binding var district: String
    @Binding var addressLine: String
    var body: some View {
        Section("listing.location") {
            Picker("search.city.title", selection: $cityId) {
                Text("common.select").tag("")
                ForEach(cities) { Text($0.name).tag($0.id) }
            }
            .onChange(of: cityId) { _, id in
                if let city = cities.first(where: { $0.id == id }) {
                    if latitude.isEmpty, let lat = city.latitude {
                        latitude = String(lat)
                    }
                    if longitude.isEmpty, let lon = city.longitude {
                        longitude = String(lon)
                    }
                }
            }
            BusinessInputField(
                "listing.location.latitude",
                text: $latitude,
                icon: "location",
                keyboard: .numbersAndPunctuation
            )
            BusinessInputField(
                "listing.location.longitude",
                text: $longitude,
                icon: "location",
                keyboard: .numbersAndPunctuation
            )
            BusinessInputField("listing.location.district", text: $district)
            BusinessInputField("listing.location.address", text: $addressLine)
        }
    }
}
