import UIKit

final class PasswordField: UIView {

    var hasValidationError = false {
        didSet { updateColors() }
    }

    let textField: UITextField = {
        let textField = UITextField()

        textField.font = .systemFont(ofSize: 15)
        textField.textColor = AppColors.titleText
        textField.tintColor = AppColors.titleText

        textField.isSecureTextEntry = true
        textField.textContentType = .password
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none

        return textField
    }()

    private lazy var visibilityButton: UIButton = {
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(systemName: "eye"),
            for: .normal
        )

        button.tintColor = AppColors.iconColor
        button.imageView?.contentMode = .scaleAspectFit

        button.addTarget(
            self,
            action: #selector(togglePasswordVisibility),
            for: .touchUpInside
        )

        return button
    }()

    private lazy var lockImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "lock")
        )

        imageView.tintColor = AppColors.iconColor
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    private let horizontalInset: CGFloat = 16
    private let iconSpacing: CGFloat = 12
    private let lockSize: CGFloat = 20
    private let buttonSize: CGFloat = 24

    init(placeholder: String) {
        super.init(frame: .zero)

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppColors.placeholderText]
        )
        setupUI()
        registerTraitChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: 56
        )
    }

    private func setupUI() {
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.masksToBounds = true

        addSubview(lockImageView)
        addSubview(textField)
        addSubview(visibilityButton)

        updateColors()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateColors()
    }

    private func updateColors() {
        backgroundColor = AppColors.surfaceBackground

        layer.borderColor =
            (hasValidationError ? AppColors.errorColor : AppColors.borderColor)
            .resolvedColor(with: traitCollection)
            .cgColor

        textField.textColor = AppColors.titleText
        textField.tintColor = AppColors.titleText

        lockImageView.tintColor = AppColors.iconColor
        visibilityButton.tintColor = AppColors.iconColor
    }

    private func registerTraitChanges() {
        registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (view: Self, _) in
            view.updateColors()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()

        lockImageView.frame = CGRect(
            x: horizontalInset,
            y: (bounds.height - lockSize) / 2,
            width: lockSize,
            height: lockSize
        )

        visibilityButton.frame = CGRect(
            x: bounds.width - horizontalInset - buttonSize,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )

        let textFieldX =
            lockImageView.frame.maxX + iconSpacing

        let textFieldWidth =
            visibilityButton.frame.minX
            - iconSpacing
            - textFieldX

        textField.frame = CGRect(
            x: textFieldX,
            y: 0,
            width: max(0, textFieldWidth),
            height: bounds.height
        )
    }

    @objc
    private func togglePasswordVisibility() {
        let wasSecure = textField.isSecureTextEntry

        textField.isSecureTextEntry.toggle()

        visibilityButton.setImage(
            UIImage(
                systemName: wasSecure
                    ? "eye.slash"
                    : "eye"
            ),
            for: .normal
        )

        if let text = textField.text,
            textField.isFirstResponder
        {
            textField.text = nil
            textField.insertText(text)
        }
    }
}
