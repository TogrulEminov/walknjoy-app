import SwiftUI

struct HomeAllCategoriesView: View {
    let categories: [CategoryModel]

    var body: some View {
        List(categories) { category in
            NavigationLink(value: HomeNavigationRoute.category(id: category.id)) {
                Text(category.name)
            }
        }
        .navigationTitle("home.categories.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}
