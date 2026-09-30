import SwiftUI
import UIKit

/// Bridges the UIKit password field so its text and validation state stay in sync with SwiftUI.
struct PasswordFieldRepresentable: UIViewRepresentable {
    @Environment(\.fieldHasValidationError) private var hasValidationError

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
        uiView.hasValidationError = hasValidationError
        // Refresh the coordinator's binding when SwiftUI recreates this representable value.
        context.coordinator.parent = self
        if uiView.textField.text != text {
            uiView.textField.text = text
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: PasswordField,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        return CGSize(width: width, height: uiView.intrinsicContentSize.height)
    }

    final class Coordinator: NSObject {
        var parent: PasswordFieldRepresentable

        init(parent: PasswordFieldRepresentable) {
            self.parent = parent
        }

        @objc
        func textChanged(_ sender: UITextField) {
            // Publish UIKit editing changes through the current SwiftUI binding.
            parent.text = sender.text ?? ""
        }
    }
}
