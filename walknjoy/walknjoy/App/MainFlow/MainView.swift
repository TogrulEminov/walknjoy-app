//
//  MainView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            profileView
        }
    }
}
extension MainView {
    private var profileView: some View {
        ProfileView()
            .tabItem {
                Label("profile.main", systemImage: "person")
            }
    }
}
