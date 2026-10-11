import SwiftUI

struct AppTextField: View {
    @Environment(\.fieldHasValidationError) private var hasValidationError
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalizationType: UITextAutocapitalizationType = .sentences

    private var capitalization: TextInputAutocapitalization {
        switch autocapitalizationType {
        case .none: return .never
        case .words: return .words
        case .allCharacters: return .characters
        default: return .sentences
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color.iconColor).accessibilityHidden(true)
            TextField(LocalizedStringKey(placeholder), text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled(keyboardType == .emailAddress)
        }
        .font(.body)
        .foregroundStyle(Color.titleText)
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(hasValidationError ? Color.errorColor : Color.borderColor) }
    }
}
