import SwiftUI

private struct FieldValidationErrorKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var fieldHasValidationError: Bool {
        get { self[FieldValidationErrorKey.self] }
        set { self[FieldValidationErrorKey.self] = newValue }
    }
}
 
private struct FieldValidationModifier: ViewModifier {
    let value: String
    let isValid: Bool
    let message: String?
    @State private var hasEdited = false

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content
                .environment(\.fieldHasValidationError, hasEdited && !isValid)
            if hasEdited && !isValid, let message {
                Label(LocalizedStringKey(message), systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color.errorColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: value) { _, _ in hasEdited = true }
    }
}

extension View {
    func fieldValidation(_ field: ValidatedField) -> some View {
        modifier(FieldValidationModifier(
            value: field.value,
            isValid: field.isValid,
            message: field.errorMessage
        ))
    }
}
