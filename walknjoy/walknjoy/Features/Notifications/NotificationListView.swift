import SwiftUI

struct NotificationListView: View {
    @Environment(AppState.self) private var appState
    @Environment(NotificationViewModel.self) private var model
    @State private var selected: AppNotification?

    var body: some View {
        List {
            Section {
                Toggle(
                    "notifications.unreadOnly",
                    isOn: Binding(
                        get: { model.unreadOnly },
                        set: { model.setUnreadOnly($0) }
                    )
                )
                Button("notifications.readAll") {
                    Task { await model.markAllRead() }
                }
                .disabled(model.unreadCount == 0 || model.isMarkingRead)
            }
            .listRowBackground(Color.surfaceBg)
            if let error = model.error {
                Section {
                    Text(error).foregroundStyle(Color.errorC)
                    Button("common.retry") { Task { await model.refresh() } }
                }.listRowBackground(Color.surfaceBg)
            }
            if model.socketState == .failed {
                Text("notifications.offlineHint").font(.footnote)
                    .foregroundStyle(Color.description)
                    .listRowBackground(Color.surfaceBg)
            }
            if model.isLoading && model.notifications.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
            } else if model.visibleNotifications.isEmpty {
                ContentUnavailableView(
                    "notifications.empty",
                    systemImage: "bell",
                    description: Text("notifications.emptyDescription")
                )
                .listRowBackground(Color.clear)
            }
            ForEach(model.visibleNotifications) { notification in
                Button {
                    Task {
                        if await model.markRead(notification) {
                            selected = notification
                        }
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(
                            systemName: notification.isRead
                                ? "bell" : "bell.badge.fill"
                        )
                        .foregroundStyle(Color.icon)
                        .frame(width: 24)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(notification.title).font(
                                notification.isRead ? .body : .headline
                            )
                            .foregroundStyle(Color.title)
                            Text(notification.body).font(.subheadline)
                                .lineLimit(3)
                                .foregroundStyle(Color.description)
                            if let date = notification.displayDate {
                                Text(date, style: .relative).font(.caption)
                                    .foregroundStyle(Color.description)
                            }
                        }
                        Spacer(minLength: 0)
                        if !notification.isRead {
                            Circle().fill(Color.button).frame(
                                width: 8,
                                height: 8
                            ).padding(.top, 6)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(model.isMarkingRead)
                .listRowBackground(Color.surfaceBg)
            }
            if model.hasMore {
                Button("common.loadMore") { Task { await model.loadMore() } }
                    .disabled(model.isLoading)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .tint(Color.button)
        .navigationTitle("notifications.title")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.refresh() }
        .task { await model.refresh() }
        .navigationDestination(item: $selected) { notification in
            if appState.currentUserRole == .customer
                || appState.currentUserRole == .provider,
                notification.type == "new_message",
                let id = notification.data?.conversationId,
                NotificationData.isSafeIdentifier(id)
            {
                ChatDetailView(conversationID: id)
            } else {
                NotificationContentView(notification: notification)
            }
        }
    }
}

// Navigation remains internal. Booking details are intentionally outside this feature's scope.
private struct NotificationContentView: View {
    let notification: AppNotification
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(notification.title).font(.title2.bold()).foregroundStyle(
                    Color.title
                )
                Text(notification.body).foregroundStyle(Color.description)
                if let date = notification.displayDate {
                    Text(
                        date,
                        format: .dateTime.day().month().year().hour().minute()
                    ).font(.caption).foregroundStyle(Color.description)
                }
                if let slug = notification.data?.validatedListingSlug {
                    NavigationLink("notifications.openListing") {
                        NotificationListingDestination(slug: slug)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color.appBg)
        .navigationTitle("notifications.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationListingDestination: View {
    let slug: String
    @Environment(\.locale) private var locale
    @State private var model = NotificationListingViewModel()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let listing = model.listing {
                    Text(listing.title ?? String(localized: "listing.untitled"))
                        .font(.title2.bold())
                    if let description = listing.description {
                        Text(description)
                    }
                    Text(
                        verbatim:
                            "\(NSDecimalNumber(decimal: listing.basePrice).stringValue) \(listing.currency)"
                    )
                    if let details = listing.details {
                        ListingDetailsSummary(details: details)
                    }
                } else if let error = model.error {
                    Text(error).foregroundStyle(Color.errorC)
                    Button("common.retry") {
                        Task {
                            await model.load(
                                slug: slug,
                                locale: locale.language.languageCode?.identifier
                                    ?? "az"
                            )
                        }
                    }
                } else {
                    ProgressView()
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
        }
        .background(Color.appBg)
        .navigationTitle("listing.title")
        .task {
            await model.load(
                slug: slug,
                locale: locale.language.languageCode?.identifier ?? "az"
            )
        }
    }

}

extension AppNotification {
    fileprivate var displayDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        return formatter.date(from: createdAt)
            ?? ISO8601DateFormatter().date(from: createdAt)
    }
}
