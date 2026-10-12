import SwiftUI

struct PreferencesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    selectionRow(
                        title: Text(language.title),
                        symbol: "globe",
                        selected: appState.language == language
                    ) { appState.selectLanguage(language) }
                }
            } header: {
                Text("profile.language")
            } footer: {
                Text("settings.language.description")
            }
            .listRowBackground(Color.surfaceBackground)

            Section {
                ForEach(Mode.allCases, id: \.self) { mode in
                    selectionRow(
                        title: Text(modeTitle(mode)),
                        symbol: modeIcon(mode),
                        selected: appState.mode == mode
                    ) { appState.selectMode(mode) }
                }
            } header: {
                Text("profile.appearance")
            } footer: {
                Text("settings.appearance.description")
            }
            .listRowBackground(Color.surfaceBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("settings.preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectionRow(
        title: Text,
        symbol: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .foregroundStyle(Color.iconColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Color.appBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                title.foregroundStyle(Color.titleText)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        selected ? Color.buttonBackground : Color.borderColor
                    )
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func modeTitle(_ mode: Mode) -> LocalizedStringKey {
        switch mode {
        case .system: "settings.mode.system"
        case .light: "settings.mode.light"
        case .dark: "settings.mode.dark"
        }
    }

    private func modeIcon(_ mode: Mode) -> String {
        switch mode {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}
