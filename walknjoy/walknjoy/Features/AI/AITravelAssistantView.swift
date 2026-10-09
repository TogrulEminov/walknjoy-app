import SwiftUI

@MainActor
struct AITravelAssistantView: View {
    @Environment(AppState.self) private var appState
    @State private var model = AITravelAssistantViewModel()
    @State private var draft = ""
    @State private var showConversations = false

    private var locale: String { appState.language.rawValue }

    var body: some View {
        VStack(spacing: 0) {
            if !model.messages.isEmpty {
                conversation
            } else {
                welcome
            }
            composer
        }
        .background(Color.appBg)
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .listingDetails(let listing):
                ListingDetailView(data: listing)
            case .allCategories:
                EmptyView()
            }
        }
        .navigationTitle("ai.assistant.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showConversations = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("ai.conversations.title")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.startNewConversation()
                    draft = ""
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("ai.newConversation")
            }
        }
        .sheet(isPresented: $showConversations) {
            conversationsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.appBackground)
        }
        .task(id: locale) { await model.load(locale: locale) }
        .alert(
            "ai.error.title",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if $0 { model.dismissError() } }
            )
        ) {
            if model.retryMessage != nil {
                Button("common.retry") {
                    Task { await model.retry(locale: locale) }
                }
            }
            Button("common.ok", role: .cancel) { model.dismissError() }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.brandYellow)
                    Text("ai.welcome.title")
                        .font(.title2.bold())
                        .foregroundStyle(Color.title)
                    Text("ai.welcome.description")
                        .font(.body)
                        .foregroundStyle(Color.description)
                }
                if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }
                if !model.suggestions.isEmpty {
                    Text("ai.suggestions.title")
                        .font(.headline)
                        .foregroundStyle(Color.title)
                    ForEach(model.suggestions) { suggestion in
                        Button {
                            Task {
                                await model.send(
                                    suggestion.prompt,
                                    locale: locale
                                )
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(Color.icon)
                                Text(suggestion.title)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.title)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .foregroundStyle(Color.description)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Color.surfaceBg,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14).stroke(
                                    Color.border
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isSending)
                    }
                }
                if let message = model.errorMessage {
                    ErrorStateView(title: "ai.error.title", message: message) {
                        Task { await model.load(locale: locale) }
                    }
                }
            }
            .padding(20)
        }
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(model.messages) { message in
                        messageView(message)
                            .id(message.id)
                    }
                    if model.isSending {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("ai.thinking")
                                .foregroundStyle(Color.description)
                        }
                        .padding(14)
                        .background(
                            Color.surfaceBg,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                }
                .padding(16)
            }
            .onChange(of: model.messages.count) { _, _ in
                if let last = model.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: AIMessage) -> some View {
        VStack(
            alignment: message.role == .user ? .trailing : .leading,
            spacing: 12
        ) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(
                    message.role == .user ? Color.white : Color.title
                )
                .padding(14)
                .background(
                    message.role == .user ? Color.icon : Color.surfaceBg,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: message.role == .user ? .trailing : .leading
                )

            if message.role == .assistant, !message.listings.isEmpty {
                VStack(spacing: 0) {
                    ForEach(message.listings) { listing in
                        SearchListingRow(
                            listing: listing,
                            isFavorite: appState.isFavorite(listing),
                            isUpdatingFavorite: appState.updatingFavoriteIDs
                                .contains(listing.id),
                            canFavorite: appState.canUseFavorites,
                            onFavorite: {
                                Task {
                                    try? await appState.setFavorite(
                                        !appState.isFavorite(listing),
                                        for: listing
                                    )
                                }
                            }
                        )
                        .padding(.horizontal, 12)
                        .background(Color.surfaceBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.border, lineWidth: 1)
                        }
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: message.role == .user ? .trailing : .leading
        )
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("ai.message.placeholder", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(12)
                .background(
                    Color.surfaceBg,
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18).stroke(Color.border)
                )
            Button {
                let text = draft
                draft = ""
                Task { await model.send(text, locale: locale) }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.appBg)
                    .frame(width: 44, height: 44)
                    .background(Color.brandYellow, in: Circle())
            }
            .disabled(
                draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || model.isSending
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBg)
    }

    private var conversationsSheet: some View {
        NavigationStack {
            List {
                Button {
                    model.startNewConversation()
                    showConversations = false
                } label: {
                    Label("ai.newConversation", systemImage: "plus")
                        .foregroundStyle(Color.icon)
                }
                ForEach(model.conversations) { item in
                    Button {
                        showConversations = false
                        Task {
                            await model.openConversation(
                                item.id,
                                locale: locale
                            )
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                item.title
                                    ?? String(
                                        localized: "ai.conversation.untitled"
                                    )
                            )
                            .font(.headline)
                            .foregroundStyle(Color.title)
                            if let lastMessage = item.lastMessage {
                                Text(lastMessage).font(.subheadline)
                                    .foregroundStyle(Color.description)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await model.deleteConversation(item.id) }
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBg)
            .navigationTitle("ai.conversations.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close") { showConversations = false }
                }
            }
        }
    }
}
