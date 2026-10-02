import SwiftUI

struct AdvantagesSection: View {

    private let advantages: [AdvantagesModel]

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    init(
        advantages: [AdvantagesModel] = AdvantagesModel.advantagesInfo
    ) {
        self.advantages = advantages
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("home.advantages.title")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.titleText)

            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 12
            ) {
                ForEach(advantages) { data in
                    advantagesCard(data)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

extension AdvantagesSection {

    fileprivate func advantagesCard(
        _ data: AdvantagesModel
    ) -> some View {
        VStack(spacing: 12) {

            ZStack {
                Circle()
                    .fill(Color.brandYellow.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: data.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.iconColor)
            }

            Text(data.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.titleText)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(data.description)
                .font(.system(size: 12))
                .foregroundStyle(Color.descriptionText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 170)
        .padding(14)
        .background(Color.surfaceBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    Color.borderColor.opacity(0.5),
                    lineWidth: 1
                )
        }
    }
}

#Preview {
    AdvantagesSection(advantages: AdvantagesModel.advantagesInfo)
}
