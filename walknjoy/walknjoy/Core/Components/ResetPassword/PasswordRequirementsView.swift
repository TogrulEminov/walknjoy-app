//
//  PasswordRequirementsView.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 18.09.26.
//

import SwiftUI

struct PasswordRequirementsView: View {
    let password: String

    private var hasMinimumLength: Bool {
        (8...128).contains(password.count)
    }
    private var hasUppercaseAndLowercase: Bool {
        password.range(of: "[A-Za-z]", options: .regularExpression) != nil
    }
    private var hasNumberOrSpecialCharacter: Bool {
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "password.requirements.title"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.titleText.opacity(0.65)).padding(.bottom,12)

            requirementRow(
                "password.requirements.lengthRange",
                isValid: hasMinimumLength
            )

            requirementRow(
                "password.requirements.letter",
                isValid: hasUppercaseAndLowercase
            )

            requirementRow(
                "password.requirements.digit",
                isValid: hasNumberOrSpecialCharacter
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.titleText.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func requirementRow(_ key: String, isValid: Bool) -> some View {
        let isEmpty = password.isEmpty
        let color: Color =
            isEmpty ? Color.titleText.opacity(0.25) : isValid ? .green : Color.errorColor

        return HStack(spacing: 7) {
            Image(
                systemName: isValid
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.system(size: 14))
            .foregroundStyle(color)

            Text(String(localized: .init(key)))
                .font(.system(size: 13))
                .foregroundStyle(
                    isEmpty
                        ? Color.titleText.opacity(0.45)
                        : isValid ? .green : Color.errorColor
                )
        }
    }
}
#Preview {
    PasswordRequirementsView(password: "Togrul023")
}
