import SwiftUI

struct TravelPlannerActionBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let session: PlannerSession
    let isLoading: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    @ViewBuilder var body: some View {
        let canContinue =
            session.input.type != "single_select"
            && session.input.type != "none"
        if canContinue || session.canGoBack {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 12) {
                        actionButtons(session, canContinue: canContinue)
                    }
                } else {
                    HStack(spacing: 12) {
                        actionButtons(session, canContinue: canContinue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBg)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.border.opacity(0.5)).frame(height: 1)
            }
        }
    }

    @ViewBuilder private func actionButtons(
        _ session: PlannerSession,
        canContinue: Bool
    ) -> some View {
        if session.canGoBack {
            Button {
                onBack()
            } label: {
                Label("planner.back", systemImage: "chevron.backward")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.title)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(
                        maxWidth: dynamicTypeSize.isAccessibilitySize
                            || !canContinue ? .infinity : nil,
                        minHeight: 56
                    )
                    .background(
                        Color.surfaceBg,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16).stroke(
                            Color.border,
                            lineWidth: 1
                        )
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .opacity(isLoading ? 0.55 : 1)
        }
        if canContinue {
            let title: LocalizedStringKey =
                session.input.type == "confirmation"
                ? "planner.showOptions" : "planner.continue"
            Button {
                onContinue()
            } label: {
                HStack(spacing: 10) {
                    if isLoading { ProgressView().tint(Color.buttonText) }
                    Text(title).multilineTextAlignment(.center)
                    if !isLoading {
                        Image(systemName: "arrow.forward").accessibilityHidden(
                            true
                        )
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.buttonText)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    Color.buttonBackground,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityLabel(Text(title))
        }
    }

}
