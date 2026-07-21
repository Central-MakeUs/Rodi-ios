//
//  RodiClusterCountMarkerView.swift
//  Rodi
//

import UIKit

/// Kakao 지도 클러스터 숫자에 맞춰 폭을 계산해 직접 그리는 말풍선 마커다.
final class RodiClusterCountMarkerView: UIView {
    private enum Constants {
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 3
        static let cornerRadius: CGFloat = 6
        static let tailWidth: CGFloat = 12
        static let tailHeight: CGFloat = 8
        static let shadowInset: CGFloat = 4
        static let primaryColor = UIColor(red: 0.439, green: 0.384, blue: 1, alpha: 1)
    }

    private let countText: String
    private let font = UIFont.pretendard(size: 14, weight: .medium)

    init(countText: String) {
        self.countText = countText
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        let textSize = measuredTextSize
        return CGSize(
            width: ceil(textSize.width + Constants.horizontalPadding * 2 + Constants.shadowInset * 2),
            height: ceil(textSize.height + Constants.verticalPadding * 2 + Constants.tailHeight + Constants.shadowInset * 2)
        )
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let textSize = measuredTextSize
        let chipRect = CGRect(
            x: Constants.shadowInset,
            y: Constants.shadowInset,
            width: rect.width - Constants.shadowInset * 2,
            height: ceil(textSize.height + Constants.verticalPadding * 2)
        )
        let tailTopY = chipRect.maxY - 1
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: rect.midX - Constants.tailWidth / 2, y: tailTopY))
        tailPath.addLine(to: CGPoint(x: rect.midX + Constants.tailWidth / 2, y: tailTopY))
        tailPath.addLine(to: CGPoint(x: rect.midX, y: tailTopY + Constants.tailHeight))
        tailPath.close()
        let markerPath = UIBezierPath(roundedRect: chipRect, cornerRadius: Constants.cornerRadius)
        markerPath.append(tailPath)

        context.saveGState()
        context.setShadow(
            offset: .zero,
            blur: 1.5,
            color: UIColor.black.withAlphaComponent(0.3).cgColor
        )
        Constants.primaryColor.setFill()
        markerPath.fill()
        context.restoreGState()

        let textRect = CGRect(
            x: chipRect.minX + Constants.horizontalPadding,
            y: chipRect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        (countText as NSString).draw(
            in: textRect,
            withAttributes: [
                .font: font,
                .foregroundColor: UIColor.white
            ]
        )
    }

    func renderedImage() -> UIImage {
        let size = intrinsicContentSize
        frame = CGRect(origin: .zero, size: size)

        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(bounds)
        }
    }

    private var measuredTextSize: CGSize {
        (countText as NSString).size(withAttributes: [.font: font])
    }
}
