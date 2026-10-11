import SwiftUI

struct HomeAllCategoriesView: View {
    let categories: [CategoryModel]
    let onSelect: (CategoryModel) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    onSelect(category)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(category.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.titleText)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.surfaceBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .navigationTitle("home.categories.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}
