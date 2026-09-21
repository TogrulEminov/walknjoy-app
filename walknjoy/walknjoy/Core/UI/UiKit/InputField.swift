import SnapKit
import UIKit

final class InputField: UIView {

    private let iconImageView = UIImageView()
    let textField = UITextField()

    init(
        placeholder: String,
        icon: String? = nil
    ) {
        super.init(frame: .zero)

        setupUI()
        setupConstraints()

        textField.placeholder = placeholder

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
        backgroundColor = .secondarySystemBackground

        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.masksToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .secondaryLabel

        textField.font = .systemFont(ofSize: 15)
        textField.textColor = .label
        textField.tintColor = .label

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

    private func updateColors() {
        backgroundColor = .secondarySystemBackground

        layer.borderColor =
            UIColor.separator
            .resolvedColor(with: traitCollection)
            .cgColor

        iconImageView.tintColor = .secondaryLabel
        textField.textColor = .label
        textField.tintColor = .label
    }

    private func registerTraitChanges() {
        registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (view: Self, _) in
            view.updateColors()
        }
    }
}
