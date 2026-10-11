import SwiftUI

struct AppPasswordField: View {
    @Environment(\.fieldHasValidationError) private var hasValidationError
    @Binding var text: String
    let placeholder: String
    @State private var isVisible = false
    @FocusState private var focusedField: Bool?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock").foregroundStyle(Color.iconColor).accessibilityHidden(true)
            Group {
                if isVisible { TextField(LocalizedStringKey(placeholder), text: $text).focused($focusedField, equals: true) }
                else { SecureField(LocalizedStringKey(placeholder), text: $text).focused($focusedField, equals: false) }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            Button {
                let wasFocused = focusedField != nil
                isVisible.toggle()
                if wasFocused { focusedField = isVisible }
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(Color.iconColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isVisible ? LocalizedStringKey("common.hidePassword") : LocalizedStringKey("common.showPassword")))
        }
        .font(.body)
        .foregroundStyle(Color.titleText)
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(minHeight: 56)
        .background(Color.surfaceBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(hasValidationError ? Color.errorColor : Color.borderColor) }
    }
}
