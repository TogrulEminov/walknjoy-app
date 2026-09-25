import SnapKit
import UIKit

final class InputField: UIView {

    private let iconImageView = UIImageView()
    var hasValidationError = false {
        didSet { updateColors() }
    }

    let textField = UITextField()

    init(
        placeholder: String,
        icon: String? = nil
    ) {
        super.init(frame: .zero)

        setupUI()
        registerTraitChanges()
        setupConstraints()

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppColors.placeholderText]
        )

        if let icon {
            iconImageView.image = UIImage(systemName: icon)
        }
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
        backgroundColor = AppColors.surfaceBackground

        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.masksToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppColors.iconColor

        textField.font = .systemFont(ofSize: 15)
        textField.textColor = AppColors.titleText
        textField.tintColor = AppColors.titleText

        updateColors()

        addSubview(iconImageView)
        addSubview(textField)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        textField.snp.makeConstraints { make in
            make.leading
                .equalTo(iconImageView.snp.trailing)
                .offset(12)

            make.trailing
                .equalToSuperview()
                .offset(-16)

            make.top.bottom.equalToSuperview()
        }
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

        iconImageView.tintColor = AppColors.iconColor
        textField.textColor = AppColors.titleText
        textField.tintColor = AppColors.titleText
    }

    private func registerTraitChanges() {
        registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (view: Self, _) in
            view.updateColors()
        }
    }
}
