import SnapKit
import UIKit

final class PasswordField: UIView {

    let textField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 15)
        textField.textColor = .label
        textField.isSecureTextEntry = true
        textField.textContentType = nil
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none

        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        return textField
    }()

    private lazy var visibilityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.tintColor = .systemGray
        button.imageView?.contentMode = .scaleAspectFit

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )

        button.addTarget(
            self,
            action: #selector(togglePasswordVisibility),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var lockImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock"))
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit

        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )

        return imageView
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()

    init(placeholder: String) {
        super.init(frame: .zero)
        textField.placeholder = placeholder
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        layer.masksToBounds = true

        stackView.addArrangedSubview(lockImageView)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(visibilityButton)

        addSubview(stackView)
    }

    private func setupConstraints() {
        snp.makeConstraints {
            $0.height.equalTo(56)
        }

        stackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        lockImageView.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }

        visibilityButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }

    @objc
    private func togglePasswordVisibility() {
        let wasSecure = textField.isSecureTextEntry
        textField.isSecureTextEntry.toggle()

        let icon = wasSecure ? "eye.slash" : "eye"
        visibilityButton.setImage(UIImage(systemName: icon), for: .normal)

        if let text = textField.text, textField.isFirstResponder {
            textField.text = nil
            textField.insertText(text)
        }
    }
}
