//
//  OnboardingPage.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import Foundation

struct OnboardingPage: Identifiable {
    let id: Int
    let imageName: String
    let icon: String?
    let title: LocalizedStringResource
    let description: LocalizedStringResource
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            imageName: "onboarding_story",
            icon: nil,
            title: "onboarding.story.title",
            description: "onboarding.story.description"
        ),
        OnboardingPage(
            id: 1,
            imageName: "onboarding_stay",
            icon: "bed.double.fill",
            title: "onboarding.stay.title",
            description: "onboarding.stay.description"
        ),
        OnboardingPage(
            id: 2,
            imageName: "onboarding_experience",
            icon: "tent.fill",
            title: "onboarding.experience.title",
            description: "onboarding.experience.description"
        ),
        OnboardingPage(
            id: 3,
            imageName: "onboarding_plan",
            icon: "heart.fill",
            title: "onboarding.plan.title",
            description: "onboarding.plan.description"
        ),

    ]
}
