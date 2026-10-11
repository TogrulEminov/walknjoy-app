import SwiftUI

struct TravelPlannerResultsView: View {
    let s: PlannerSession
    let model: TravelPlannerViewModel
    let onOpen: (PlannerItem, Bool) -> Void
    @ViewBuilder var body: some View {
        if let notice = s.notice { TravelPlannerChatBubble(text: notice, user: false) }
        Text("planner.individualServices").font(.footnote).foregroundStyle(
            Color.description
        )
        if !model.items.isEmpty {
            Text("planner.withinBudget").font(.headline)
            ForEach(model.items) { item in
                TravelPlannerResultCard(item: item, isDisabled: model.isOpeningListing || model.isLoading,
                    onDetails: { onOpen(item, false) }, onBook: { onOpen(item, true) }) }
        }
        if !model.alternatives.isEmpty {
            Text("planner.overBudget").font(.headline)
            ForEach(model.alternatives) { item in
                TravelPlannerResultCard(item: item, isDisabled: model.isOpeningListing || model.isLoading,
                    onDetails: { onOpen(item, false) }, onBook: { onOpen(item, true) }) }
        }
        if s.results?.meta.hasNextPage == true {
            Button("planner.more") { Task { await model.more() } }.disabled(
                model.isLoading
            )
        } else if model.items.isEmpty && model.alternatives.isEmpty {
            Text("planner.empty")
        }
        if let changes = s.results?.suggestedChanges, !changes.isEmpty,
            s.canGoBack
        {
            Text("planner.changeSuggestions").font(.footnote)
            if model.suggestedSteps.isEmpty {
                Button("planner.changeAnswers") { Task { await model.back() } }
                    .disabled(model.isLoading)
            } else {
                ForEach(model.suggestedSteps, id: \.self) { step in
                    Button(LocalizedStringKey("planner.edit." + step)) {
                        Task { await model.rewind(to: step) }
                    }
                    .disabled(model.isLoading)
                }
            }
        }
    }

}
