//
//  SubmitButton.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 22.09.26.
//

import SwiftUI

struct SubmitButton: View {

    let title: LocalizedStringKey
    var icon: String? = "arrow.right"
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    init(
        title: LocalizedStringKey,
        icon: String? = "arrow.right",
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    /// Form validity and loading are supplied by the shared form state.
    init<Field: Hashable>(
        title: LocalizedStringKey,
        icon: String? = "arrow.right",
        form: FormState<Field>,
        isBlocked: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            icon: icon,
            isLoading: form.isSubmitting,
            isDisabled: !form.canSubmit || isBlocked,
            action: action
        )
    }

    var body: some View {
        Button(
            action: action,
            label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .tint(isDisabled ? Color.descriptionText : Color.buttonText)
                    } else {
                        Text(title)

                        if let icon {
                            Image(systemName: icon)
                        }
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isDisabled ? Color.descriptionText : Color.buttonText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isDisabled ? Color.disabledBackground : Color.buttonBackground
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
        )
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}
