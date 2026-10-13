import PhotosUI
import SwiftUI

struct ListingTypeSelectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List(ListingType.allCases) { type in
            NavigationLink {
                CreateListingView(type: type)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.iconColor)
                        .frame(width: 36, height: 36)
                        .background(
                            Color.appBackground,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    Text(type.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.titleText)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.surfaceBackground)
            .listRowSeparatorTint(Color.borderColor)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .foregroundStyle(Color.titleText)
        .tint(Color.titleText)
        .navigationTitle("listing.typeSelection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("listing.typeSelection")
                    .font(.headline)
                    .foregroundStyle(Color.titleText)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(colorScheme, for: .navigationBar)
    }
}

struct CreateListingView: View {
    let type: ListingType
    var onMutation: @MainActor @Sendable () -> Void = {}
    var body: some View {
        ListingEditorView(
            model: ListingEditorViewModel(type: type, onMutation: onMutation)
        )
    }
}
struct EditListingView: View {
    let listing: ProviderListingCardDTO
    var locale: ListingLocale = .az
    var onMutation: @MainActor @Sendable () -> Void = {}
    var body: some View {
        ListingEditorView(
            model: ListingEditorViewModel(
                type: listing.type,
                id: listing.id,
                locale: locale,
                canEdit: listing.actions.canEdit,
                canSubmit: listing.actions.canSubmit,
                onMutation: onMutation
            )
        )
    }
}

struct ListingEditorView: View {
    @State var model: ListingEditorViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingClose = false
    @State private var selectingImages = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    var body: some View {
        @Bindable var model = model
        Form {
            Group {
                if model.busy { ProgressView() }
                if let error = model.error {
                    Section {
                        Text(error).foregroundStyle(Color.errorColor)
                        if !model.loaded {
                            Button("common.retry") {
                                Task { await model.load() }
                            }
                        }
                    }
                }
                if let notice = model.notice {
                    Text(notice).foregroundStyle(Color.titleText)
                }
                if let refreshError = model.refreshError {
                    Section {
                        Text(refreshError).foregroundStyle(Color.errorC)
                        Button("common.retry") {
                            Task { await model.refreshFromServer() }
                        }
                    }
                }
                if model.status == .rejected, let reason = model.rejectionReason
                {
                    Section("listing.rejection.title") {
                        Text(reason).foregroundStyle(Color.errorC)
                    }
                }
                Section("listing.title") {
                    Label(model.type.title, systemImage: model.type.icon)
                    Text(
                        model.status?.localizedTitle
                            ?? String(localized: "listing.status.unknown")
                    )
                    Picker(
                        "listing.contentLocale",
                        selection: Binding(
                            get: { model.locale },
                            set: { locale in
                                Task { await model.changeLocale(locale) }
                            }
                        )
                    ) {
                        ForEach(ListingLocale.allCases) {
                            Text($0.rawValue.uppercased()).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Group {
                    Section("listing.translation.section") {
                        BusinessInputField(
                            "listing.field.title",
                            text: $model.translation.title,
                            icon: "textformat"
                        )
                        BusinessInputField(
                            "listing.field.slug",
                            text: $model.translation.slug,
                            icon: "link",
                            capitalization: .none
                        )
                        BusinessInputField(
                            "listing.field.shortDescription",
                            text: $model.translation.shortDescription,
                            icon: "text.alignleft"
                        )
                        EditorScreen(html: $model.translation.description).id(
                            model.locale
                        )
                        Text(
                            verbatim:
                                "\(model.translation.title.count)/200 · \(model.translation.shortDescription.count)/300 · \(model.translation.description.count)/5000"
                        )
                        .font(.caption).foregroundStyle(Color.descriptionText)
                    }
                    Section("listing.pricing.section") {
                        CategoryPickerView(
                            categories: model.categories,
                            selection: $model.categoryId
                        )
                        BusinessInputField(
                            "listing.field.price",
                            text: $model.price,
                            icon: "banknote",
                            keyboard: .decimalPad
                        )
                        Picker(
                            "listing.field.currency",
                            selection: $model.currency
                        ) {
                            ForEach(
                                Array(
                                    Set(["AZN", "USD", "EUR", model.currency])
                                ).sorted(),
                                id: \.self
                            ) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    LocationPickerView(
                        cities: model.cities,
                        cityId: $model.cityId,
                        latitude: $model.latitude,
                        longitude: $model.longitude,
                        district: $model.translation.district,
                        addressLine: $model.translation.addressLine
                    )
                    switch model.type {
                    case .stay: StayDetailsForm(details: $model.stay)
                    case .tour: TourDetailsForm(details: $model.tour)
                    case .activity:
                        ActivityDetailsForm(details: $model.activity)
                    case .experience:
                        ExperienceDetailsForm(details: $model.experience)
                    }
                    AmenityPickerView(
                        amenities: model.amenities,
                        selection: $model.selectedAmenities
                    )
                }
                .disabled(!model.loaded || !model.editable)
                Section("listing.media") {
                    if !model.media.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(model.media) { media in
                                    VStack {
                                        AsyncImage(url: URL(string: media.url))
                                        { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.placeholderText.opacity(0.2)
                                        }
                                        .frame(width: 120, height: 90)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 10)
                                        )
                                        HStack {
                                            if media.isCover {
                                                Text("listing.media.cover")
                                                    .font(.caption)
                                            }
                                            Button(role: .destructive) {
                                                Task {
                                                    await model.removeMedia(
                                                        media
                                                    )
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 8,
                        matching: .images
                    ) {
                        Label("listing.media.add", systemImage: "plus")
                    }
                    .onChange(of: selectedPhotos) { _, items in
                        Task {
                            selectingImages = true
                            defer {
                                selectingImages = false
                                selectedPhotos = []
                            }
                            for item in items {
                                guard
                                    let data = try? await item.loadTransferable(
                                        type: Data.self
                                    )
                                else { continue }
                                await model.addPhoto(data)
                            }
                        }
                    }
                    if model.id == nil {
                        Text("listing.media.createFirst").font(.caption)
                            .foregroundStyle(Color.descriptionText)
                    }
                }
                if let message = model.validationMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.errorC)
                }
                if model.editable {
                    Section {
                        Button("listing.action.save") {
                            Task { await model.save() }
                        }
                        .disabled(!model.canSave)
                        if model.canSubmit {
                            Button(
                                model.status == .rejected
                                    ? String(
                                        localized: "listing.action.resubmit"
                                    )
                                    : String(localized: "listing.action.submit")
                            ) {
                                Task { await model.save(submit: true) }
                            }
                            .disabled(!model.canSubmitWithCurrentInput)
                        }
                    }
                }
            }
            .listRowBackground(Color.surfaceBackground)
        }
        .listRowBackground(Color.surfaceBackground)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .presentationBackground(Color.appBackground)
        .foregroundStyle(Color.titleText)
        .tint(Color.buttonBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(colorScheme, for: .navigationBar)
        .pickerStyle(.menu)
        .disabled(model.busy || selectingImages)
        .navigationTitle(
            model.id == nil
                ? String(localized: "listing.create.title")
                : String(localized: "listing.edit.title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(
            model.hasUnsavedChanges || model.busy || selectingImages
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.close")) {
                    if model.hasUnsavedChanges {
                        confirmingClose = true
                    } else {
                        dismiss()
                    }
                }
                .disabled(model.busy || selectingImages)
            }
        }
        .confirmationDialog(
            "listing.unsaved.title",
            isPresented: $confirmingClose,
            titleVisibility: .visible
        ) {
            Button("listing.unsaved.discard", role: .destructive) { dismiss() }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("listing.unsaved.message")
        }
        .onReceive(NotificationCenter.default.publisher(for: .listingsChanged)) { event in
            if let id = event.object as? String, id == model.id { dismiss() }
        }
        .task { await model.load() }
    }
}
