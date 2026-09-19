import SwiftUI
import UIKit

struct PasswordFieldRepresentable: UIViewRepresentable {
    @Binding var text: String
    let placeHolder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PasswordField {
        let view = PasswordField(placeholder: placeHolder)
        view.textField.text = text

        view.textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged),
            for: .editingChanged
        ) 

        return view
    }

    func updateUIView(_ uiView: PasswordField, context: Context) {
        context.coordinator.parent = self
        if uiView.textField.text != text {
            uiView.textField.text = text
        }
    }

    final class Coordinator: NSObject {
        var parent: PasswordFieldRepresentable

        init(parent: PasswordFieldRepresentable) {
            self.parent = parent
        }

        @objc
        func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }
    }
}
