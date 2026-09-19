import SnapKit
//
//  UiTextField.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import UIKit

final class InputField: UIView {
    private let iconImageView = UIImageView()

    let textField = UITextField()
    init(placeholder: String, icon: String? = nil) {
        super.init(frame: .zero)
        setupUI()
        setupConstraits()
        textField.placeholder = placeholder
        if let icon {
            iconImageView.image = UIImage(systemName: icon)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray3.cgColor
        layer.masksToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemGray

        textField.font = .systemFont(ofSize: 15)
        textField.textColor = .label

        addSetupSubview()
    }

    private func addSetupSubview() {
        addSubview(iconImageView)
        addSubview(textField)
    }

    private func setupConstraits() {
        heightAnchor.constraint(equalToConstant: 56).isActive = true

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }
    }
}
