//
//  ProfileMenuItem.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 23.09.26.
//

import SwiftUI

struct ProfileMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let destination: ProfileDestination
}
