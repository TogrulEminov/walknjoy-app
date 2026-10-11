import SwiftUI

struct ListingListView: View {
    @State private var model = ProviderListingsViewModel()
    @State private var editing: ProviderListingCardDTO?
    @State private var archiveTarget: ProviderListingCardDTO?
    @State private var creating = false

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(spacing: 18) {
                pageHeading
                filters
                if let error = model.error ?? model.catalogError {
                    Text(error).foregroundStyle(Color.errorC)
                    Button("common.retry") {
                        Task {
                            await model.loadCategories()
                            await model.reload()
                        }
                    }
                }
                if model.loading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                } else if model.listings.isEmpty && model.error == nil
                    && !model.loading
                {
                    ContentUnavailableView(
                        model.query.isFiltered || model.query.sort != .newest
                            ? "provider.list.filteredEmpty" : "listing.empty",
                        systemImage: "building.2",
                        description: Text("provider.list.emptyHint")
                    )
                }
                LazyVStack(spacing: 10) {
                    ForEach(model.listings) { listing in
                        ProviderListingRowView(
                            listing: listing,
                            busy: model.mutatingID != nil,
                            onOpen: { editing = listing },
                            onSubmit: { Task { await model.submit(listing) } },
                            onArchive: { archiveTarget = listing }
                        )
                    }
                }
                if let error = model.nextPageError {
                    Text(error).foregroundStyle(Color.errorC)
                    Button("common.retry") { Task { await model.loadMore() } }
                }
                if model.loadingNext { ProgressView() }
                if model.hasMore {
                    Button("common.loadMore") {
                        Task { await model.loadMore() }
                    }
                    .disabled(model.loadingNext)
                }
            }
            .padding(20)
        }
        .background(Color.appBg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: model.query) { await model.reload(debounce: true) }
        .task(
            id:
                "\(model.query.locale.rawValue)-\(model.query.type?.rawValue ?? "all")"
        ) { await model.loadCategories() }
        .refreshable { await model.reload() }
        .sheet(item: $editing, onDismiss: refresh) { listing in
            NavigationStack {
                EditListingView(
                    listing: listing,
                    locale: model.query.locale,
                    onMutation: refresh
                )
            }
        }
        .sheet(isPresented: $creating, onDismiss: refresh) {
            NavigationStack { ListingTypeSelectionView() }
        }
        .confirmationDialog(
            "provider.archive.title",
            isPresented: Binding(
                get: { archiveTarget != nil },
                set: { if $0 { archiveTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("provider.archive.action", role: .destructive) {
                if let target = archiveTarget {
                    Task { await model.archive(target) }
                }
                archiveTarget = nil
            }
            Button("common.cancel", role: .cancel) { archiveTarget = nil }
        } message: {
            Text("provider.archive.message")
        }
        .alert(
            "error.title",
            isPresented: Binding(
                get: { model.mutationError != nil },
                set: { if $0 { model.mutationError = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { model.mutationError = nil }
        } message: {
            Text(model.mutationError ?? "")
        }
    }

    private var filters: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.icon)
                TextField("provider.list.search", text: $model.query.q)
                    .submitLabel(.search)
                    .onChange(of: model.query.q) { _, value in
                        if value.count > 150 {
                            model.query.q = String(value.prefix(150))
                        }
                    }
                if !model.query.q.isEmpty {
                    Button {
                        model.query.q = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("common.reset")
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.appBg, in: RoundedRectangle(cornerRadius: 14))
            HStack(spacing: 8) {
                Menu {
                    Button("provider.list.allStatuses") { model.query.status = nil }
                    ForEach([ListingStatus.draft, .pendingReview, .published, .rejected, .archived], id: \.rawValue) { status in
                        Button { model.query.status = status } label: { Text(status.localizedTitle) }
                    }
                } label: {
                    filterChip(title: model.query.status?.localizedTitle ?? String(localized: "provider.list.allStatuses"), systemImage: "circle.lefthalf.filled")
                }
                .accessibilityLabel("provider.list.status")

                Menu {
                    Button("search.type.all") { model.query.type = nil; model.query.categoryId = nil }
                    ForEach(ListingType.allCases) { type in
                        Button { model.query.type = type; model.query.categoryId = nil } label: { Text(type.title) }
                    }
                } label: {
                    filterChip(title: model.query.type.map(listingTypeTitle) ?? String(localized: "search.type.all"), systemImage: "square.grid.2x2")
                }
                .accessibilityLabel("search.type")

                Menu {
                    ForEach(ProviderListingSort.allCases) { sort in
                        Button { model.query.sort = sort } label: { Text(sort.title) }
                    }
                } label: {
                    filterChip(title: sortTitle(model.query.sort), systemImage: "arrow.up.arrow.down")
                }
                .accessibilityLabel("search.sort")
            }

            HStack(spacing: 8) {
                Menu {
                    Button("search.filter.any") { model.query.categoryId = nil }
                    ForEach(model.categories) { category in
                        Button(category.name) { model.query.categoryId = category.id }
                    }
                } label: {
                    filterChip(
                        title: model.categories.first { $0.id == model.query.categoryId }?.name ?? String(localized: "listing.category"),
                        systemImage: "tag"
                    )
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("listing.category")

                Menu {
                    ForEach(ListingLocale.available) { locale in
                        Button(locale.rawValue.uppercased()) { model.query.locale = locale }
                    }
                } label: {
                    filterChip(title: model.query.locale.rawValue.uppercased(), systemImage: "globe")
                }
                .frame(width: 88)
                .accessibilityLabel("listing.locale")
            }
        }
        .font(.subheadline)
        .tint(Color.button)
        .padding(14)
        .background(Color.surfaceBg, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color.border) }
    }

    private func filterChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.button)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.title)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.description)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(Color.appBg, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Color.border, lineWidth: 1) }
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func listingTypeTitle(_ type: ListingType) -> String {
        switch type {
        case .stay: String(localized: "listing.type.stay")
        case .tour: String(localized: "listing.type.tour")
        case .activity: String(localized: "listing.type.activity")
        case .experience: String(localized: "listing.type.experience")
        }
    }

    private func sortTitle(_ sort: ProviderListingSort) -> String {
        switch sort {
        case .newest: String(localized: "search.sort.newest")
        case .priceAscending: String(localized: "search.sort.priceAsc")
        case .priceDescending: String(localized: "search.sort.priceDesc")
        case .featured: String(localized: "search.sort.featured")
        }
    }

    private var pageHeading: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "listing.myListings"))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.title)
                Text(String(format: String(localized: "provider.list.heading.countFormat"), model.totalCount))
                    .contentTransition(.numericText(value: Double(model.totalCount)))
                    .font(.subheadline)
                    .foregroundStyle(Color.description)
            }
            Spacer()
            Button { creating = true } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appBg)
                    .frame(width: 46, height: 46)
                    .background(Color.brandY, in: Circle())
            }
            .accessibilityLabel("listing.action.create")
        }
        .padding(.top, 6)
    }
    private func refresh() { Task { await model.reload() } }

}

private struct ProviderListingRowView: View {
    let listing: ProviderListingCardDTO
    let busy: Bool
    let onOpen: () -> Void
    let onSubmit: () -> Void
    let onArchive: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    thumbnail
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(listing.title ?? String(localized: "listing.untitled"))
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            statusBadge
                        }
                        HStack(spacing: 8) {
                            if let city = listing.location?.city {
                                Label(city, systemImage: "mappin.and.ellipse")
                            }
                            if let category = listing.category { Text(category.name) }
                        }
                        .font(.caption).foregroundStyle(Color.description).lineLimit(1)
                        HStack {
                            Text(verbatim: "\(listing.basePrice) \(listing.currency)").font(.subheadline.weight(.semibold))
                            Spacer()
                            if let rating = listing.rating.average {
                                Label {
                                    Text(verbatim: "\(rating.formatted(.number.precision(.fractionLength(1)))) (\(listing.rating.count))")
                                } icon: {
                                    Image(systemName: "star.fill")
                                }
                            } else {
                                Text("provider.list.noReviews")
                            }
                        }
                        .font(.caption).foregroundStyle(Color.description)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(busy)

            Menu {
                Button(listing.actions.canEdit ? "common.edit" : "common.view", action: onOpen)
                if listing.actions.canSubmit {
                    Button("listing.action.submit", action: onSubmit)
                }
                if listing.actions.canArchive {
                    Button("provider.archive.action", systemImage: "archivebox", role: .destructive, action: onArchive)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.description)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .disabled(busy)
        }
        .padding(10)
        .foregroundStyle(Color.title)
        .background(Color.surfaceBg)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.border).frame(height: 1) }
    }

    private var thumbnail: some View {
        Group {
            if let cover = listing.coverMedia, cover.type == "image", let url = URL(string: cover.url) {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { placeholder }
            } else {
                placeholder
            }
        }
        .frame(width: 76, height: 76)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var placeholder: some View {
        Color.border.overlay { Image(systemName: "photo").foregroundStyle(Color.icon) }
    }

    private var statusBadge: some View {
        Text(listing.status.localizedTitle)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7).padding(.vertical, 4)
            .background(Color.brandY.opacity(0.22), in: Capsule())
    }
}

extension ProviderListingSort {
    fileprivate var title: LocalizedStringKey {
        switch self {
        case .newest: "search.sort.newest"
        case .priceAscending: "search.sort.priceAsc"
        case .priceDescending: "search.sort.priceDesc"
        case .featured: "search.sort.featured"
        }
    }
}

struct ListingDetailsSummary: View {
    let details: ListingDetails
    var body: some View {
        switch details {
        case .stay(let value):
            Text(
                String(format: String(localized: "listing.stay.summaryFormat"), ListingDetailFormatting.property(value.propertyType), value.maxGuests)
            )
            if let nights = value.minimumNights {
                Text(String(format: String(localized: "listing.nights.minimumFormat"), nights))
            }
        case .tour(let value):
            duration(value.durationMinutes, participants: value.maxParticipants)
            if let meeting = value.meetingPoint { Text(meeting) }
            Text(value.languages.joined(separator: ", "))
        case .activity(let value):
            duration(value.durationMinutes, participants: value.maxParticipants)
            if let difficulty = value.difficulty { Text(difficulty) }
        case .experience(let value):
            duration(value.durationMinutes, participants: value.maxParticipants)
        }
    }
    @ViewBuilder private func duration(_ minutes: Int?, participants: Int?)
        -> some View
    {
        if let minutes { Text(String(format: String(localized: "listing.duration.minutesFormat"), minutes)) }
        if let participants {
            Text(String(format: String(localized: "listing.participants.maximumFormat"), participants))
        }
    }
}
