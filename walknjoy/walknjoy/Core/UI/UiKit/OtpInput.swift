import UIKit
import SnapKit

final class WNJOTPTextField: UITextField {

    var onBackspaceWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        if text?.isEmpty ?? true {
            onBackspaceWhenEmpty?()
        }

        super.deleteBackward()
    }
}

final class OtpInput: UIView, UITextFieldDelegate {

    private let digitCount: Int
    private var textFields: [WNJOTPTextField] = []
    private let stackView = UIStackView()

    var onCodeChanged: ((String) -> Void)?

    var code: String {
        textFields.compactMap(\.text).joined()
    }

    override var intrinsicContentSize: CGSize {
        let minimumWidth = CGFloat(digitCount * 44 + (digitCount - 1) * 8)

        return CGSize(
            width: minimumWidth,
            height: 56
        )
    }

    init(digitCount: Int = 6) {
        self.digitCount = digitCount
        super.init(frame: .zero)

        setupStackView()
        createTextFields()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually

        addSubview(stackView)
    }

    private func setupConstraints() {
        snp.makeConstraints {
            $0.height.equalTo(56)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func createTextFields() {
        for index in 0..<digitCount {
            let field = WNJOTPTextField()

            field.tag = index
            configure(field)

            field.addTarget(
                self,
                action: #selector(textChanged(_:)),
                for: .editingChanged
            )

            field.onBackspaceWhenEmpty = { [weak self] in
                self?.moveToPreviousField(from: index)
            }

            textFields.append(field)
            stackView.addArrangedSubview(field)
        }
    }

    private func configure(_ field: WNJOTPTextField) {
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 20, weight: .semibold)
        field.textColor = .label
        field.backgroundColor = .systemBackground

        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.systemGray4.cgColor

        field.delegate = self
        field.textContentType = .oneTimeCode
        field.autocorrectionType = .no

        field.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(44)
        }
    }

    @objc
    private func textChanged(_ textField: UITextField) {
        guard let field = textField as? WNJOTPTextField else {
            return
        }

        if let text = field.text, text.count > 1 {
            field.text = String(text.prefix(1))
        }

        if !(field.text ?? "").isEmpty {
            moveToNextField(from: field.tag)
        }

        onCodeChanged?(code)
    }

    private func moveToNextField(from index: Int) {
        guard index + 1 < textFields.count else {
            endEditing(true)
            return
        }

        textFields[index + 1].becomeFirstResponder()
    }

    private func moveToPreviousField(from index: Int) {
        guard index > 0 else {
            return
        }

        let previousField = textFields[index - 1]
        previousField.text = ""
        previousField.becomeFirstResponder()

        onCodeChanged?(code)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string.isEmpty {
            return true
        }

        return string.allSatisfy(\.isNumber) && string.count == 1
    }

    func setCode(_ newCode: String) {
        let digits = Array(newCode.prefix(digitCount))

        for (index, field) in textFields.enumerated() {
            field.text = index < digits.count ? String(digits[index]) : ""
        }
    }

    func clear() {
        setCode("")
        textFields.first?.becomeFirstResponder()
        onCodeChanged?("")
    }
}
