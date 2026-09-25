import SwiftUI

struct NotificationPreferencesView: View {
    @State private var model = NotificationPreferencesViewModel()

    var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                LoadingStateView()
            case .error(let message):
                ErrorStateView(
                    title: "notifications.loadError",
                    message: message,
                    retryTitle: "retry"
                ) { Task { await model.load() } }
            case .loaded:
                preferencesForm
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle("profile.notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }

    private var preferencesForm: some View {
        Form {
            Section {
                preference(
                    "notifications.bookings", description: "notifications.bookings.description",
                    symbol: "calendar.badge.clock", isOn: $model.bookingUpdates
                )
                preference(
                    "notifications.messages", description: "notifications.messages.description",
                    symbol: "bubble.left.and.bubble.right", isOn: $model.messages
                )
            } header: {
                Text("notifications.activity")
            } footer: {
                Text("notifications.description")
            }
            .listRowBackground(Color.surfaceBackground)

            Section {
                preference(
                    "notifications.ai", description: "notifications.ai.description",
                    symbol: "sparkles", isOn: $model.aiUpdates
                )
                preference(
                    "notifications.marketing", description: "notifications.marketing.description",
                    symbol: "megaphone", isOn: $model.marketing
                )
            } header: {
                Text("notifications.discover")
            }
            .listRowBackground(Color.surfaceBackground)

            Section {
                if case .error(let message) = model.saveState {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.errorColor)
                }
                if model.saveState == .success && !model.form.hasChanges {
                    Label("notifications.saved", systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.titleText)
                }
                SubmitButton(title: "profile.saveChanges", icon: "checkmark", form: model.form) {
                    Task { await model.save() }
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
        .scrollContentBackground(.hidden)
        .disabled(model.saveState == .loading)
    }

    private func preference(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey,
        symbol: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(Color.iconColor)
                    .frame(width: 32, height: 32)
                    .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.body.weight(.medium)).foregroundStyle(Color.titleText)
                    Text(description).font(.caption).foregroundStyle(Color.descriptionText)
                }
            }
            .padding(.vertical, 6)
        }
        .tint(Color.buttonBackground)
    }
}

#Preview {
    NavigationStack { NotificationPreferencesView() }
}
