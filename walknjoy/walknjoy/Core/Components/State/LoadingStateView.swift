//
//  LoadingStateView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 21.09.26.
//

import SwiftUI

struct LoadingStateView: View {
    var message: LocalizedStringKey?
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)

            if let message {
                Text(message).font(.system(size: 14)).foregroundStyle(
                    .secondary
                )
            }
        }
    }
}
