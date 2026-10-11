import SwiftUI

struct PhoneFieldRepresentable: UIViewRepresentable {
    @Environment(\.fieldHasValidationError) private var hasValidationError

    let country: PhoneCountry

    @Binding var phone: String
    @Binding var isComplete: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            country: country,
            phone: $phone,
            isComplete: $isComplete
        )
    }

    func makeUIView(context: Context) -> InputField {
        let view = InputField(
            placeholder: country.dialCode,
            icon: "phone"
        )

        view.textField.keyboardType = .phonePad
        view.textField.textContentType = .telephoneNumber
        view.textField.delegate = context.coordinator

        updateTextField(view.textField)

        return view
    }

    func updateUIView(
        _ uiView: InputField,
        context: Context
    ) {
        uiView.hasValidationError = hasValidationError
        context.coordinator.country = country
        context.coordinator.phone = $phone
        context.coordinator.isComplete = $isComplete

        uiView.textField.placeholder = country.dialCode
        updateTextField(uiView.textField)
    }

    private func updateTextField(_ textField: UITextField) {
        let digits = normalizedDigits(phone)

        let formatted = Coordinator.format(
            digits,
            country: country
        )

        if textField.text != formatted {
            textField.text = formatted
        }
    }

    private func normalizedDigits(_ value: String) -> String {
        let digits = value.filter(\.isNumber)

        return String(digits.prefix(country.digitCount))
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var country: PhoneCountry
        var phone: Binding<String>
        var isComplete: Binding<Bool>

        init(
            country: PhoneCountry,
            phone: Binding<String>,
            isComplete: Binding<Bool>
        ) {
            self.country = country
            self.phone = phone
            self.isComplete = isComplete
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let currentText = textField.text ?? ""
            let prefix = country.dialCode + " "

            if range.location < (prefix as NSString).length {
                return false
            }

            guard let swiftRange = Range(range, in: currentText) else {
                return false
            }

            let replacement = currentText.replacingCharacters(
                in: swiftRange,
                with: string
            )

            var digits = replacement.filter(\.isNumber)
            let countryDigits = country.dialCode.filter(\.isNumber)

            if digits.hasPrefix(countryDigits) {
                digits.removeFirst(countryDigits.count)
            }

            if string.isEmpty,
               range.length == 1,
               range.location == (currentText as NSString).length - 1,
               currentText.last == " ",
               !digits.isEmpty {
                digits.removeLast()
            }

            digits = String(digits.prefix(country.digitCount))

            textField.text = Self.format(
                digits,
                country: country
            )

            phone.wrappedValue = digits
            isComplete.wrappedValue =
                digits.count == country.digitCount

            return false
        }

        static func format(
            _ digits: String,
            country: PhoneCountry
        ) -> String {
            var result = country.dialCode + " "
            var position = digits.startIndex

            for groupSize in country.groups {
                guard position < digits.endIndex else {
                    break
                }

                let end = digits.index(
                    position,
                    offsetBy: groupSize,
                    limitedBy: digits.endIndex
                ) ?? digits.endIndex

                if result != country.dialCode + " " {
                    result += " "
                }

                result += digits[position..<end]
                position = end
            }

            return result
        }
    }
}
