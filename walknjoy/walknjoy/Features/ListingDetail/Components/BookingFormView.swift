import SwiftUI

struct BookingFormView: View {
    @Bindable var viewModel: BookingViewModel
    var onSuccess: (BookingsModel) -> Void = { _ in }
    @State private var dateSelection: StayDateField?
    private enum StayDateField: String, Identifiable {
        case checkIn, checkOut
        var id: String { rawValue }
    }
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let listing = viewModel.listing {
                            VStack(alignment: .leading, spacing: 8) {
                                if let image = listing.media.first(where: {
                                    $0.isCover && $0.type == "image"
                                })
                                    ?? listing.media.first(where: {
                                        $0.type == "image"
                                    })
                                {
                                    RemoteImageView(path: image.url) {
                                        Color.surfaceBackground
                                    }
                                    .frame(height: 130).clipped().clipShape(
                                        RoundedRectangle(cornerRadius: 12)
                                    )
                                }
                                Text(listing.title ?? "").font(.headline)
                                if case .stay(let details) = listing.details {
                                    Text(
                                        String(
                                            format: String(
                                                localized:
                                                    "booking.minimumNights"
                                            ),
                                            viewModel.minimumNights
                                        )
                                    )
                                    if let time = details.checkInFrom {
                                        Text(
                                            String(
                                                localized:
                                                    "listing.detail.checkIn"
                                            ) + ": " + time
                                        )
                                    }
                                    if let time = details.checkOutUntil {
                                        Text(
                                            String(
                                                localized:
                                                    "listing.detail.checkOut"
                                            ) + ": " + time
                                        )
                                    }
                                }
                            }.font(.subheadline).padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    Color.surfaceBackground,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                        }
                        headerSection

                        VStack(spacing: 20) {
                            if viewModel.isStay {
                                bookingSection(
                                    title: "listing.detail.booking.dates"
                                ) {
                                    VStack(spacing: 16) {
                                        dateField(
                                            label: "listing.detail.checkIn",
                                            field: .checkIn
                                        )
                                        fieldError("checkIn")
                                        dateField(
                                            label: "listing.detail.checkOut",
                                            field: .checkOut
                                        )
                                        fieldError("checkOut")
                                        if case .loading = viewModel
                                            .sessionsState
                                        {
                                            ProgressView()
                                        }
                                        if case .error(let message) = viewModel
                                            .sessionsState
                                        {
                                            Text(message).foregroundStyle(
                                                Color.errorColor
                                            )
                                            Button("common.retry") {
                                                Task {
                                                    await viewModel.loadSessions()
                                                }
                                            }
                                        }
                                        if viewModel.availability != nil,
                                            !viewModel.datesAvailable
                                        {
                                            Text("booking.dates.chooseValid")
                                                .foregroundStyle(
                                                    Color.errorColor
                                                )
                                        }
                                        Text("booking.calendar.hint")
                                            .font(.caption)
                                            .foregroundStyle(Color.descriptionText)
                                    }
                                }
                            } else {
                                bookingSection(title: "booking.sessions.title")
                                {
                                    sessionsSection
                                    fieldError("sessionId")
                                }
                            }

                            bookingSection(title: "listing.detail.guests") {
                                VStack(spacing: 16) {
                                    stepperField(
                                        label: "listing.detail.adults",
                                        value: $viewModel.adults,
                                        range:
                                            1...max(
                                                1,
                                                viewModel.guestLimit
                                                    - viewModel.children
                                            ),
                                        onIncrement: { viewModel.adults += 1 },
                                        onDecrement: {
                                            viewModel.adults = max(
                                                1,
                                                viewModel.adults - 1
                                            )
                                        }
                                    )
                                    stepperField(
                                        label: "listing.detail.children",
                                        value: $viewModel.children,
                                        range:
                                            0...max(
                                                0,
                                                viewModel.guestLimit
                                                    - viewModel.adults
                                            ),
                                        onIncrement: {
                                            viewModel.children += 1
                                        },
                                        onDecrement: {
                                            viewModel.children = max(
                                                0,
                                                viewModel.children - 1
                                            )
                                        }
                                    )
                                }
                            }

                            fieldError("adults")
                            fieldError("children")
                            fieldError("participants")
                            bookingSection(title: "listing.detail.note") {
                                TextField(
                                    "listing.detail.notePlaceholder",
                                    text: $viewModel.customerNote
                                )
                                .font(.subheadline)
                                .foregroundStyle(Color.titleText)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(
                                    Color.appBackground,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12).stroke(
                                        Color.borderColor,
                                        lineWidth: 1
                                    )
                                )
                                .lineLimit(3)
                                fieldError("customerNote")
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .padding(20)
                }
                .background(Color.appBackground)

            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footerButton.background(Color.appBackground)
            }
            .disabled(viewModel.isBusy)
            .navigationTitle("listing.detail.bookingTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .foregroundStyle(Color.descriptionText)
                }
            }
            .overlay {
                if viewModel.state == .checkingAvailability
                    || viewModel.state == .submitting
                {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView(
                            viewModel.state == .checkingAvailability
                                ? "listing.detail.checkingAvailability"
                                : "listing.detail.booking"
                        )
                        .padding()
                        .background(
                            Color.appBackground,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16).stroke(
                                Color.borderColor
                            )
                        )
                    }
                }
            }
            .alert(
                "error.title",
                isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(viewModel.error ?? "")
            }
        }
        .task { await viewModel.loadSessions() }
        .onChange(of: viewModel.adults) { _, _ in viewModel.validateSelection()
        }
        .onChange(of: viewModel.children) { _, _ in
            viewModel.validateSelection()
        }
        .sheet(item: $dateSelection) { field in
            NavigationStack {
                StayAvailabilityCalendar(
                    selectedDate: field == .checkIn ? viewModel.checkIn : viewModel.checkOut,
                    canSelect: { date in
                        field == .checkIn
                            ? viewModel.canSelectCheckIn(date)
                            : viewModel.canSelectCheckOut(date)
                    },
                    onSelect: { date in
                        if field == .checkIn {
                            viewModel.selectCheckIn(date)
                        } else {
                            viewModel.checkOut = date
                            viewModel.fieldErrors = [:]
                        }
                        dateSelection = nil
                    }
                )
                .padding()
                .navigationTitle(LocalizedStringKey(field == .checkIn ? "listing.detail.checkIn" : "listing.detail.checkOut"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel") { dateSelection = nil }
                    }
                }
            }
            .presentationDetents([.height(520), .large])
        }
        .interactiveDismissDisabled(viewModel.isBusy)
    }

    @ViewBuilder private func fieldError(_ key: String) -> some View {
        if let message = viewModel.fieldErrors[key] {
            Text(message).font(.caption).foregroundStyle(Color.errorColor)
        }
    }

    @ViewBuilder private var sessionsSection: some View {
        switch viewModel.sessionsState {
        case .idle, .loading:
            ProgressView("booking.sessions.loading").frame(maxWidth: .infinity)
        case .error(let message):
            VStack(spacing: 12) {
                Text(message).font(.subheadline).foregroundStyle(
                    Color.errorColor
                )
                Button("common.retry") {
                    Task { await viewModel.loadSessions() }
                }
            }
        case .loaded:
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "booking.sessions.empty",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.sessions) { session in
                        Button {
                            viewModel.selectedSessionId = session.id
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: viewModel.selectedSessionId
                                        == session.id
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundStyle(Color.iconColor)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(
                                        session.startsAt,
                                        format: .dateTime.day().month(
                                            .abbreviated
                                        ).year().hour().minute()
                                    )
                                    .font(.subheadline.bold())
                                    Text(
                                        session.endsAt,
                                        format: .dateTime.day().month(
                                            .abbreviated
                                        ).hour().minute()
                                    )
                                    .font(.caption)
                                    Text(
                                        String(
                                            format: String(
                                                localized:
                                                    "booking.sessions.remaining"
                                            ),
                                            session.remaining
                                        )
                                    )
                                    .font(.caption)
                                    if session.remaining
                                        < viewModel.participants
                                    {
                                        Text("booking.sessions.insufficient")
                                            .font(.caption).foregroundStyle(
                                                Color.errorColor
                                            )
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(Color.titleText)
                            .padding(12)
                            .background(
                                Color.appBackground,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canSelect(session))
                        .opacity(viewModel.canSelect(session) ? 1 : 0.5)
                        .accessibilityAddTraits(
                            viewModel.selectedSessionId == session.id
                                ? .isSelected : []
                        )
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("listing.detail.bookingSubtitle")
                .font(.title3.bold())
                .foregroundStyle(Color.titleText)
            Text("listing.detail.bookingSubtitleDesc")
                .font(.caption)
                .foregroundStyle(Color.descriptionText)
        }
        .padding(.bottom, 8)
    }

    private func bookingSection<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.titleText)

            content()
                .padding(16)
                .background(
                    Color.surfaceBackground,
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(
                        Color.borderColor,
                        lineWidth: 1
                    )
                )
        }
    }

    private func dateField(
        label: LocalizedStringKey,
        field: StayDateField
    ) -> some View {
        Button {
            dateSelection = field
        } label: {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(Color.descriptionText)
                Spacer()
                Text(field == .checkIn ? viewModel.checkIn : viewModel.checkOut,
                     format: .dateTime.day().month(.abbreviated).year())
                    .foregroundStyle(Color.titleText)
                Image(systemName: "calendar").foregroundStyle(Color.titleText)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.availability == nil)
    }

    private func stepperField(
        label: LocalizedStringKey,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(
                Color.descriptionText
            )
            Spacer()
            HStack(spacing: 16) {
                Button {
                    onDecrement()
                } label: {
                    Image(systemName: "minus").font(.caption.bold()).frame(
                        minWidth: 44,
                        minHeight: 44
                    )
                }
                .disabled(value.wrappedValue <= range.lowerBound)

                Text("\(value.wrappedValue)").font(.subheadline.bold())
                    .foregroundStyle(Color.titleText)

                Button {
                    onIncrement()
                } label: {
                    Image(systemName: "plus").font(.caption.bold()).frame(
                        minWidth: 44,
                        minHeight: 44
                    )
                }
                .disabled(value.wrappedValue >= range.upperBound)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Color.appBackground,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.borderColor)
            )
        }
    }

    private var footerButton: some View {
        Button {
            Task {
                if await viewModel.submitBooking(store: .init()) {
                    if let result = viewModel.bookingResult {
                        onSuccess(result)
                    }
                    dismiss()
                }
            }
        } label: {
            Text("listing.detail.confirmBooking")
                .font(.subheadline.bold())
                .foregroundStyle(Color.brandInk)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Color.brandYellow,
                    in: RoundedRectangle(cornerRadius: 20)
                )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canBook)
        .opacity(viewModel.canBook ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
