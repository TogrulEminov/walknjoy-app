//
//  OptionListView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 08.10.26.
//

import SwiftUI

struct OptionListView<Value: Hashable>: View {
    struct Option: Identifiable {
        let title: String
        let value: Value
        var id: String { title }
    }

    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let options: [Option]
    @Binding var selection: Value

    var body: some View {
        List {
            ForEach(options) { option in
                Button {
                    selection = option.value
                    dismiss()
                } label: {
                    HStack {
                        Text(option.title)
                            .foregroundStyle(
                                option.value == selection
                                    ? Color.button : Color.title
                            )
                        Spacer()
                        if option.value == selection {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.button)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.surfaceBg)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
