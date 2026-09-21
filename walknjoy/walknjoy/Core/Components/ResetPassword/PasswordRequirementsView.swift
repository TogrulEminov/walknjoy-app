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
        password.count >= 8
    }
    private var hasUppercaseAndLowercase: Bool {
        password.contains(where: \.isUppercase)
            && password.contains(where: \.isLowercase)
    }
    private var hasNumberOrSpecialCharacter: Bool {
        password.contains(where: \.isNumber)
            || password.contains(where: { !$0.isLetter && !$0.isNumber })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "password.requirements.title"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.primary.opacity(0.65)).padding(.bottom,12)

            requirementRow(
                "password.requirements.length",
                isValid: hasMinimumLength
            )

            requirementRow(
                "password.requirements.uppercaseLowercase",
                isValid: hasUppercaseAndLowercase
            )

            requirementRow(
                "password.requirements.numberOrSpecial",
                isValid: hasNumberOrSpecialCharacter
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func requirementRow(_ key: String, isValid: Bool) -> some View {
        let isEmpty = password.isEmpty
        let color: Color =
            isEmpty ? Color.primary.opacity(0.25) : isValid ? .green : .red

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
                        ? Color.primary.opacity(0.45)
                        : isValid ? .green : .red
                )
        }
    }
}
#Preview {
    PasswordRequirementsView(password: "Togrul023")
}
