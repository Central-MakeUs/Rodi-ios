//
//  RodiUserLocationMarkerImages.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit
import SwiftUI

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func makeOrbitingDirectionFanImage(from fanImage: UIImage, bodySize: CGSize) -> UIImage {
        let canvasSide = max(bodySize.width, bodySize.height)
            + fanImage.size.height * 2
            + Constants.userDirectionFanCanvasPadding * 2
        let canvasSize = CGSize(width: canvasSide, height: canvasSide)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let bodyRadius = min(bodySize.width, bodySize.height) / 2
        let fanOrigin = CGPoint(
            x: center.x - fanImage.size.width / 2,
            y: center.y - bodyRadius - fanImage.size.height + Constants.userDirectionFanOverlap
        )

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { _ in
            fanImage.draw(in: CGRect(origin: fanOrigin, size: fanImage.size))
        }
    }

    func makeUserLocationMarkerImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Constants.userLocationMarkerCanvasSize)
        return renderer.image { context in
            let diameter = Constants.userLocationMarkerDiameter
            let origin = CGPoint(
                x: (Constants.userLocationMarkerCanvasSize.width - diameter) / 2,
                y: (Constants.userLocationMarkerCanvasSize.height - diameter) / 2
            )
            let outerRect = CGRect(origin: origin, size: CGSize(width: diameter, height: diameter))
            let innerRect = outerRect.insetBy(
                dx: Constants.userLocationMarkerBorderWidth,
                dy: Constants.userLocationMarkerBorderWidth
            )

            context.cgContext.saveGState()
            context.cgContext.setShadow(
                offset: .zero,
                blur: 3,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: outerRect)
            context.cgContext.restoreGState()

            UIColor(RodiColor.primary).setFill()
            context.cgContext.fillEllipse(in: innerRect)
        }
    }

    func makeUserDirectionMarkerImage() -> UIImage {
        let markerSize = Constants.directionMarkerSize
        let inset = Constants.directionMarkerCanvasInset
        let canvasSize = CGSize(
            width: markerSize.width + inset * 2,
            height: markerSize.height + inset * 2
        )
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let triangle = UIBezierPath()
            triangle.move(to: CGPoint(x: canvasSize.width / 2, y: inset))
            triangle.addLine(to: CGPoint(x: inset + markerSize.width, y: inset + markerSize.height))
            triangle.addLine(to: CGPoint(x: inset, y: inset + markerSize.height))
            triangle.close()

            context.cgContext.setShadow(
                offset: .zero,
                blur: 3,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            UIColor(RodiColor.primary).setFill()
            triangle.fill()
        }
    }
}
#endif
