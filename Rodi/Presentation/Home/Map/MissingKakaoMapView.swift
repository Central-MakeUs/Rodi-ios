//
//  MissingKakaoMapView.swift
//  Rodi
//

import UIKit
import SnapKit
import Then

final class MissingKakaoMapView: UIView {
    private let messageLabel = UILabel().then {
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .darkGray
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String) {
        messageLabel.text = message
    }
}
