import SwiftUI
 
struct BusinessInputField: View {
    let title: String
    @Binding var text: String
    var icon: String
    var keyboard: UIKeyboardType
    var capitalization: UITextAutocapitalizationType

    init(_ title: String, text: Binding<String>, icon: String = "pencil",
         keyboard: UIKeyboardType = .default,
         capitalization: UITextAutocapitalizationType = .sentences) {
        self.title = title
        self._text = text
        self.icon = icon
        self.keyboard = keyboard
        self.capitalization = capitalization
    }

    var body: some View {
        InputFieldRepresentable(
            text: $text,
            placeholder: String(localized: String.LocalizationValue(title)),
            icon: icon,
            keyboardType: keyboard,
            autocapitalizationType: capitalization
        )
        .frame(height: 56)
        .accessibilityLabel(Text(LocalizedStringKey(title)))
    }
}
