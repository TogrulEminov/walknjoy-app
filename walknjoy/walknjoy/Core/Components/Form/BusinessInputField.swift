import SwiftUI

struct BusinessInputField: View {
    @Environment(\.locale) private var locale

    let title: LocalizedStringResource
    @Binding var text: String
    var icon: String
    var keyboard: UIKeyboardType
    var capitalization: UITextAutocapitalizationType

    private var placeholder: String {
        var resource = title
        resource.locale = locale
        return String(localized: resource)
    }

    init(
        _ title: LocalizedStringResource,
        text: Binding<String>,
        icon: String = "pencil",
        keyboard: UIKeyboardType = .default,
        capitalization: UITextAutocapitalizationType = .sentences
    ) {
        self.title = title
        self._text = text
        self.icon = icon
        self.keyboard = keyboard
        self.capitalization = capitalization
    }

    var body: some View {
        InputFieldRepresentable(
            text: $text,
            placeholder: placeholder,
            icon: icon,
            keyboardType: keyboard,
            autocapitalizationType: capitalization
        )
        .frame(height: 56)
        .accessibilityLabel(Text(verbatim: placeholder))
    }
}
