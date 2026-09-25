//
//  PageIndicator.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 17.09.26.
//

import SwiftUI

struct PageIndicator: View {

    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 7) {

            ForEach(0..<totalPages, id: \.self) { index in

                Capsule()
                    .fill(
                        index == currentPage
                            ? Color.titleText
                            : Color.titleText.opacity(0.15)
                    )
                    .frame(
                        width: index == currentPage ? 20 : 7,
                        height: 7
                    )
                    .animation(
                        .easeInOut(duration: 0.25),
                        value: currentPage
                    )
            }
        }
    }
}
