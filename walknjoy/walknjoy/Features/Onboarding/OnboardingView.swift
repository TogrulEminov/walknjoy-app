//
//  OnboardingView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//
import SwiftUI

struct OnboardingView: View {

    @Environment(AppState.self) private var appState

    @State private var selectedPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {

            TabView(selection: $selectedPage) {

                ForEach(pages) { page in

                    OnboardingPageView(
                        page: page,
                        currentPage: selectedPage,
                        totalPages: pages.count,
                        isLastPage: page.id == pages.count - 1,
                        onNext: {
                            next()
                        },
                        onSkip: {
                            appState.finishOnboarding()
                        }
                    )
                    .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }.ignoresSafeArea()
    }
}

extension OnboardingView {

    private func next() {
        if selectedPage < pages.count - 1 {

            withAnimation {
                selectedPage += 1
            }

        } else {
            appState.finishOnboarding()
        }
    }
}
