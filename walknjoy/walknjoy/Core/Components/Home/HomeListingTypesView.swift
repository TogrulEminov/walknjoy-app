//
//  HomeListingTypesView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 28.09.26.
//

import SwiftUI

struct HomeListingTypesView: View {

    let onSelect: (ListingType) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(ListingType.allCases) { type in
                HomeListingTypeItem(type: type) {
                    onSelect(type)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
