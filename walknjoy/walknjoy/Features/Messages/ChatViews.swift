import Observation
import SwiftUI

struct ConversationListView: View {
    @Environment(AppState.self) private var appState
    @State private var model: ConversationListViewModel?
    @State private var subscription: UUID?
    private var identity: String {
        "\(appState.currentUserID ?? ""):\(appState.language.rawValue)"
    }
    var body: some View {
        List {
            if let model {
                if let error = model.error, !model.rows.isEmpty {
                    Text(error).foregroundStyle(Color.errorC)
                    Button("common.retry") {
                        Task {
                            await model.refresh(
                                locale: appState.language.rawValue
                            )
                        }
                    }
                }
                if model.rows.isEmpty {
                    switch model.state {
                    case .idle, .loading:
                        LoadingStateView()
                            .listRowSeparator(.hidden)
                    case .error(let error):
                        ErrorStateView(title: "error.title", message: error) {
                            Task {
                                await model.refresh(
                                    locale: appState.language.rawValue
                                )
                            }
                        }
                        .listRowSeparator(.hidden)
                    case .loaded:
                        EmptyView()
                    }
                }
                if case .loaded = model.state, model.rows.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("messages.empty")
                                .foregroundStyle(Color.titleText)
                        } icon: {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .foregroundStyle(Color.brandYellow)
                        }
                    }
                    .listRowBackground(Color.surfaceBackground)
                    .listRowSeparator(.hidden)
                }
                ForEach(model.rows) { row in
                    NavigationLink {
                        ChatDetailView(conversationID: row.id)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            AvatarImageView(
                                file: row.otherParticipant.avatarFile,
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: 5) {
                                Text(row.otherParticipant.displayName).font(
                                    .headline
                                )
                                if let title = row.context.listing?.title {
                                    Text(title).font(.caption).foregroundStyle(
                                        .secondary
                                    )
                                }
                                if row.context.type == "booking" {
                                    Text("messages.bookingContext").font(
                                        .caption
                                    ).foregroundStyle(.secondary)
                                }
                                Text(
                                    row.lastMessage?.content
                                        ?? String(
                                            localized: "messages.noMessages"
                                        )
                                ).font(.subheadline).lineLimit(2)
                                if let date = ChatFormatting.date(
                                    row.lastMessage?.createdAt ?? row.updatedAt
                                ) {
                                    Text(date, style: .relative).font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer(minLength: 0)
                            if row.unreadCount > 0 {
                                Text(
                                    row.unreadCount > 99
                                        ? "99+" : row.unreadCount.formatted()
                                )
                                .font(.system(size: 11, weight: .bold))
                                .monospacedDigit()
                                .frame(width: 28, height: 28)
                                .background(
                                    Color.brandYellow,
                                    in: Circle()
                                ).foregroundStyle(Color.brandInk)
                                .accessibilityLabel(
                                    Text("messages.unread \(row.unreadCount)")
                                )
                            }
                        }.padding(.vertical, 5)
                    }.listRowBackground(Color.surfaceBackground)
                }
                if model.hasMore {
                    Button("common.loadMore") {
                        Task {
                            await model.loadMore(
                                locale: appState.language.rawValue
                            )
                        }
                    }.disabled(model.isLoading)
                }
            } else {
                LoadingStateView()
            }
        }
        .scrollContentBackground(.hidden).background(Color.appBackground)
        .navigationTitle("messages.title")
        .task(id: identity) {
            model?.invalidate()
            guard
                appState.currentUserRole == .customer
                    || appState.currentUserRole == .provider
            else {
                model = nil
                return
            }
            let value = ConversationListViewModel(
                service: appState.conversations
            )
            model = value
            await value.refresh(locale: appState.language.rawValue)
        }
        .onAppear {
            if subscription == nil {
                subscription = appState.realtime.subscribeChat { data in
                    guard
                        let json = try? JSONSerialization.jsonObject(with: data)
                            as? [String: Any],
                        let event = json["event"] as? String,
                        [
                            "notification:new", "message:new", "message:read",
                            "realtime:connected",
                        ].contains(event)
                    else { return }
                    Task {
                        await model?.refresh(locale: appState.language.rawValue)
                    }
                }
            }
            Task { await model?.refresh(locale: appState.language.rawValue) }
        }
        .onDisappear {
            if let subscription {
                appState.realtime.unsubscribeChat(subscription)
            }
            subscription = nil
        }
        .refreshable {
            await model?.refresh(locale: appState.language.rawValue)
        }
    }
}

struct ConversationStartView: View {
    let context: ConversationStart
    @Environment(AppState.self) private var appState
    @State private var model = ConversationStartViewModel()
    var body: some View {
        Group {
            switch model.state {
            case .loaded(let id):
                ChatDetailView(conversationID: id)
            case .error(let error):
                ErrorStateView(title: "error.title", message: error) {
                    Task { await load() }
                }
            case .idle, .loading:
                LoadingStateView()
            }
        }
        .task { await load() }
        .onDisappear { model.invalidate() }
    }
    private func load() async {
        guard
            appState.currentUserRole == .customer
                || appState.currentUserRole == .provider
        else { return }
        await model.load(
            context: context,
            locale: appState.language.rawValue,
            service: appState.conversations
        )
    }
}

struct ChatDetailView: View {
    let conversationID: String
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ChatDetailViewModel?
    private var identity: String {
        "\(appState.currentUserID ?? ""):\(appState.language.rawValue):\(conversationID)"
    }
    var body: some View {
        Group {
            if let model {
                if model.hasLoadedHistory {
                    ChatScreen(model: model)
                } else {
                    switch model.state {
                    case .idle, .loading:
                        LoadingStateView()
                    case .error(let error):
                        ErrorStateView(title: "error.title", message: error) {
                            Task { await model.synchronize() }
                        }
                    case .loaded:
                        ChatScreen(model: model)
                    }
                }
            } else {
                LoadingStateView()
            }
        }
        .task(id: identity) {
            model?.stop()
            guard let user = appState.currentUserID,
                appState.currentUserRole == .customer
                    || appState.currentUserRole == .provider
            else {
                model = nil
                return
            }
            let value = ChatDetailViewModel(
                id: conversationID,
                userID: user,
                locale: appState.language.rawValue,
                service: appState.conversations,
                socket: appState.realtime
            )
            model = value
            value.setForeground(scenePhase == .active)
            await value.activate()
        }
        .onDisappear { model?.stop() }
        .onChange(of: scenePhase) { _, phase in
            model?.setForeground(phase == .active)
        }
    }
}

private struct ChatScreen: View {
    @Bindable var model: ChatDetailViewModel
    @Environment(AppState.self) private var appState
    @State private var atBottom = true
    @State private var hasNewMessages = false
    @State private var visibleIDs: Set<String> = []
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let context = model.detail?.context {
                        NavigationLink {
                            ChatContextDestination(context: context)
                        } label: {
                            Label(
                                context.listing?.title
                                    ?? String(
                                        localized: "messages.bookingContext"
                                    ),
                                systemImage: context.type == "booking"
                                    ? "ticket" : "house"
                            )
                            .font(.subheadline).frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(14).background(
                                Color.surfaceBackground,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }.buttonStyle(.plain)
                    }
                    if model.nextCursor != nil {
                        Button("messages.older") {
                            let anchor = model.messages.first(where: {
                                visibleIDs.contains($0.id)
                            })?.id
                            Task {
                                await model.loadOlder()
                                if let anchor {
                                    proxy.scrollTo(anchor, anchor: .top)
                                }
                            }
                        }.disabled(model.isLoadingOlder).frame(minHeight: 44)
                    }
                    if model.isLoadingOlder
                        || (model.isLoading && !model.hasLoadedHistory)
                    {
                        ProgressView()
                    }
                    if model.messages.isEmpty && model.outgoing.isEmpty
                        && !model.isLoading && model.error == nil
                    {
                        ContentUnavailableView(
                            "messages.noMessages",
                            systemImage: "bubble.left"
                        )
                    }
                    ForEach(
                        Array(model.messages.enumerated()),
                        id: \.element.id
                    ) { index, message in
                        VStack(spacing: 10) {
                            if isNewDay(index) {
                                dateDivider(message.createdAt)
                            }
                            ChatBubble(
                                content: message.content,
                                createdAt: message.createdAt,
                                own: message.senderId == model.userID,
                                status: message.senderId == model.userID
                                    ? (model.isRead(message)
                                        ? "messages.read" : "messages.sent")
                                    : nil
                            )
                        }
                        .id(message.id)
                    }
                    ForEach(model.outgoing) { message in
                        VStack(alignment: .trailing, spacing: 4) {
                            ChatBubble(
                                content: message.content,
                                createdAt: message.createdAt,
                                own: true,
                                status: message.status == .pending
                                    ? "messages.pending" : "messages.failed"
                            )
                            if message.status == .failed {
                                Button("common.retry") {
                                    model.retry(message.id)
                                }.frame(minHeight: 44)
                            }
                        }.frame(maxWidth: .infinity, alignment: .trailing).id(
                            message.id
                        )
                    }
                    Color.clear.frame(height: 1).id("chat-bottom")
                        .onScrollVisibilityChange { visible in
                            atBottom = visible
                            if visible { hasNewMessages = false }
                        }
                }.padding(16)
                    .scrollTargetLayout()
            }
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .defaultScrollAnchor(atBottom ? .bottom : nil, for: .sizeChanges)
            .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.6)
            { ids in
                let visible = Set(ids)
                if visibleIDs != visible { visibleIDs = visible }
                model.visibleMessages(visible)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.revision) { _, _ in
                if !atBottom { hasNewMessages = true }
            }
            .overlay(alignment: .bottomTrailing) {
                if hasNewMessages {
                    Button("messages.newMessage") {
                        proxy.scrollTo("chat-bottom", anchor: .bottom)
                        hasNewMessages = false
                    }
                    .padding(12).background(
                        Color.surfaceBackground,
                        in: Capsule()
                    ).padding(16)
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
            .background(Color.appBackground)
            .navigationTitle(
                model.participant?.displayName
                    ?? String(localized: "messages.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AvatarImageView(
                        file: model.participant?.avatarFile,
                        size: 32
                    )
                }
            }
            .refreshable { await model.synchronize() }
        }
    }
    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !model.isLive {
                Text("messages.restFallback").font(.caption).foregroundStyle(
                    .secondary
                )
            }
            if model.otherIsTyping {
                Text("messages.typing").font(.caption).foregroundStyle(
                    .secondary
                )
            }
            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(Color.errorC)
                Button("common.retry") { Task { await model.synchronize() } }
            }
            HStack(alignment: .bottom, spacing: 12) {
                TextField(
                    "messages.placeholder",
                    text: $model.draft,
                    axis: .vertical
                )
                .lineLimit(1...5).padding(12)
                .background(
                    Color.appBackground,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .accessibilityLabel("messages.placeholder")
                Button {
                    model.sendDraft()
                } label: {
                    Image(systemName: "arrow.up").font(.headline).frame(
                        width: 44,
                        height: 44
                    )
                    .background(
                        model.canSend ? Color.brandYellow : Color.borderColor,
                        in: Circle()
                    )
                    .foregroundStyle(Color.brandInk)
                }.disabled(!model.canSend).accessibilityLabel("messages.send")
            }
            if model.draft.trimmingCharacters(in: .whitespacesAndNewlines).count
                > 4000
            {
                Text("messages.tooLong").font(.caption).foregroundStyle(
                    Color.errorC
                )
            }
        }.padding(.horizontal, 16).padding(.vertical, 10).background(
            Color.surfaceBackground
        )
        .onChange(of: model.draft) { _, _ in model.draftChanged() }
    }
    private func isNewDay(_ index: Int) -> Bool {
        guard index > 0,
            let previous = ChatFormatting.date(
                model.messages[index - 1].createdAt
            ),
            let current = ChatFormatting.date(model.messages[index].createdAt)
        else { return true }
        return !Calendar.current.isDate(previous, inSameDayAs: current)
    }
    @ViewBuilder private func dateDivider(_ value: String) -> some View {
        if let date = ChatFormatting.date(value) {
            Text(date, format: .dateTime.day().month().year()).font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
private struct ChatBubble: View {
    let content: String
    let createdAt: String
    let own: Bool
    let status: LocalizedStringKey?
    var body: some View {
        HStack {
            if own { Spacer(minLength: 36) }
            VStack(alignment: own ? .trailing : .leading, spacing: 6) {
                Text(content).textSelection(.enabled).fixedSize(
                    horizontal: false,
                    vertical: true
                )
                HStack(spacing: 6) {
                    if let date = ChatFormatting.date(createdAt) {
                        Text(date, format: .dateTime.hour().minute())
                    }
                    if let status { Text(status) }
                }.font(.caption2)
            }
            .padding(12).foregroundStyle(own ? Color.brandInk : Color.titleText)
            .background(
                own ? Color.brandYellow : Color.surfaceBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .accessibilityElement(children: .combine)
            if !own { Spacer(minLength: 36) }
        }
    }
}
private struct ChatContextDestination: View {
    let context: ConversationContext
    @Environment(AppState.self) private var appState
    @State private var model = ChatContextViewModel()
    var body: some View {
        Group {
            if let id = context.bookingId, let role = appState.currentUserRole {
                BookingDetailView(bookingID: id, role: role)
            } else if let listing = model.listing {
                ListingDetailView(listing: listing)
            } else if let error = model.error {
                ErrorStateView(title: "error.title", message: error) {
                    Task { await load() }
                }
            } else if context.listing != nil {
                LoadingStateView()
            } else {
                ContentUnavailableView(
                    "messages.contextUnavailable",
                    systemImage: "house"
                )
            }
        }.task { await load() }
    }
    private func load() async {
        if context.bookingId == nil, let id = context.listing?.id {
            await model.load(id: id, locale: appState.language.rawValue)
        }
    }
}
