//
//  AdvantagesModel.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 01.10.26.
//

import SwiftUI

nonisolated struct AdvantagesModel: Identifiable {
    let id: UUID = UUID()
    let name: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
}
nonisolated extension AdvantagesModel {
    static let advantagesInfo: [AdvantagesModel] = [
        AdvantagesModel(
            name: "home.advantages.offers.title",
            description: "home.advantages.offers.description",
            icon: "sparkles"
        ),
        AdvantagesModel(
            name: "home.advantages.reviews.title",
            description: "home.advantages.reviews.description",
            icon: "star.fill"
        ),
        AdvantagesModel(
            name: "home.advantages.planning.title",
            description: "home.advantages.planning.description",
            icon: "calendar.badge.checkmark"
        ),
        AdvantagesModel(
            name: "home.advantages.providers.title",
            description: "home.advantages.providers.description",
            icon: "checkmark.shield.fill"
        ),
    ]
}
