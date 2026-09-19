//
//  TextFieldRepresentable.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//

import SwiftUI

struct InputFieldRepresentable: UIViewRepresentable {

    @Binding var text: String

    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalizationType: UITextAutocapitalizationType = .sentences

    func makeUIView(context: Context) -> InputField {
        let view = InputField(
            placeholder: placeholder,
            icon: icon
        )

        view.textField.delegate = context.coordinator

        view.textField.keyboardType = keyboardType
        view.textField.textContentType = textContentType
        view.textField.autocapitalizationType = autocapitalizationType

        view.textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged),
            for: .editingChanged
        )

        return view
    }

    func updateUIView(_ uiView: InputField, context: Context) {
        if uiView.textField.text != text {
            uiView.textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {

        private let parent: InputFieldRepresentable

        init(_ parent: InputFieldRepresentable) {
            self.parent = parent
        }

        @objc
        func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }
    }
}
