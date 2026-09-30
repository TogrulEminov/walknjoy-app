import SwiftUI

struct HomeCategoriesView: View {
    let categories: [CategoryModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(categories) { category in
                        CategoryCard(
                            category: category,
                            destination: .category(id: category.id)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("home.categories.title")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.title)

            Spacer()

            NavigationLink(value: HomeNavigationRoute.allCategories) {
                HStack(spacing: 6) {
                    Text("common.seeAll")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.icon)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

}
