import SwiftUI

@MainActor
struct ProviderBusinessProfileView: View {
    @State private var flow: ProviderFlowViewModel

    init() {
        _flow = State(initialValue: ProviderFlowViewModel())
    }

    var body: some View {
        Group {
            switch flow.state {
            case .idle, .loading:
                LoadingStateView()
            case .needsApplication:
                ErrorStateView(
                    title: "profile.error.title",
                    message: String(localized: "provider.profile.missing"),
                    retryTitle: "retry"
                ) {
                    Task { await flow.load() }
                }
            case .loaded(let profile):
                ProviderApplicationView(profile: profile, flow: flow)
            case .error(let message):
                ErrorStateView(
                    title: "profile.error.title",
                    message: message,
                    retryTitle: "retry"
                ) {
                    Task { await flow.load() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            if case .idle = flow.state {
                await flow.load()
            }
        }
    }
}
