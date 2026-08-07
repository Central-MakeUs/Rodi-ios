//
//  RodiMapHomeMarkerStyles.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func registerHomeMarkerStylesIfNeeded(with manager: LabelManager) {
        guard !didRegisterHomeMarkerStyles else { return }

        manager.addPoiStyle(
            makeImageMarkerStyle(
                styleID: Constants.homeParkingInactiveMarkerStyleID,
                assetName: "ic_parking_inactive",
                fallbackImage: makeFallbackParkingMarkerImage(),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
        )
        registeredHomeMarkerStyleIDs.insert(Constants.homeParkingInactiveMarkerStyleID)

        manager.addPoiStyle(
            makeImageMarkerStyle(
                styleID: Constants.homeParkingActiveMarkerStyleID,
                assetName: "ic_parking_active",
                fallbackImage: makeFallbackParkingMarkerImage(),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
        )
        registeredHomeMarkerStyleIDs.insert(Constants.homeParkingActiveMarkerStyleID)

        didRegisterHomeMarkerStyles = true
    }

    func registerHomeMarkerStyleIfNeeded(for marker: RodiMapMarker, styleID: String, with manager: LabelManager) {
        guard !registeredHomeMarkerStyleIDs.contains(styleID) else { return }

        switch marker.kind {
        case .course:
            manager.addPoiStyle(
                makeCourseLabelMarkerStyle(styleID: styleID, title: marker.title)
            )
        case .parking:
            break
        case .cluster:
            manager.addPoiStyle(
                makeClusterCountMarkerStyle(styleID: styleID, countText: marker.title)
            )
        }

        registeredHomeMarkerStyleIDs.insert(styleID)
    }

    func makeImageMarkerStyle(
        styleID: String,
        assetName: String,
        fallbackImage: UIImage,
        anchorPoint: CGPoint
    ) -> PoiStyle {
        let iconStyle = PoiIconStyle(
            symbol: UIImage(named: assetName) ?? fallbackImage,
            anchorPoint: anchorPoint
        )
        return PoiStyle(styleID: styleID, styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)])
    }

    func makeCourseLabelMarkerStyle(styleID: String, title: String) -> PoiStyle {
        let iconStyle = PoiIconStyle(
            symbol: makeCourseLabelMarkerImage(title: title),
            anchorPoint: CGPoint(x: 0.5, y: 0.5)
        )
        return PoiStyle(styleID: styleID, styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)])
    }

    func makeCourseLabelMarkerImage(title: String) -> UIImage {
        let displayTitle = String(title.prefix(12))
        let font = UIFont.pretendard(size: 12, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let textSize = (displayTitle as NSString).size(withAttributes: textAttributes)
        let horizontalPadding: CGFloat = 9
        let verticalPadding: CGFloat = 3
        let shadowPadding: CGFloat = 6
        let markerSize = CGSize(
            width: ceil(textSize.width + horizontalPadding * 2),
            height: ceil(textSize.height + verticalPadding * 2)
        )
        let canvasSize = CGSize(
            width: markerSize.width + shadowPadding * 2,
            height: markerSize.height + shadowPadding * 2
        )
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { context in
            let markerRect = CGRect(
                x: shadowPadding,
                y: shadowPadding,
                width: markerSize.width,
                height: markerSize.height
            )
            let path = UIBezierPath(roundedRect: markerRect, cornerRadius: 14)

            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 3),
                blur: 6,
                color: UIColor.black.withAlphaComponent(0.18).cgColor
            )
            UIColor(red: 0.439, green: 0.384, blue: 1.0, alpha: 1.0).setFill()
            path.fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

            let textRect = CGRect(
                x: markerRect.minX + horizontalPadding,
                y: markerRect.minY + verticalPadding,
                width: textSize.width,
                height: textSize.height
            )
            (displayTitle as NSString).draw(in: textRect, withAttributes: textAttributes)
        }
    }

    func makeClusterCountMarkerStyle(styleID: String, countText: String) -> PoiStyle {
        let iconStyle = PoiIconStyle(
            symbol: makeClusterCountMarkerImage(countText: countText),
            anchorPoint: CGPoint(x: 0.5, y: 1.0)
        )
        return PoiStyle(styleID: styleID, styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)])
    }

    func makeClusterCountMarkerImage(countText: String) -> UIImage {
        RodiClusterCountMarkerView(countText: countText).renderedImage()
    }

    func makeFallbackParkingMarkerImage() -> UIImage {
        let size = CGSize(width: 24, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let circleRect = CGRect(x: 3, y: 1, width: 18, height: 18)

            UIColor.black.withAlphaComponent(0.16).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 5, y: 24, width: 14, height: 4))

            UIColor(red: 0.19, green: 0.43, blue: 1.0, alpha: 1.0).setFill()
            context.cgContext.fillEllipse(in: circleRect)

            let tailPath = UIBezierPath()
            tailPath.move(to: CGPoint(x: size.width / 2, y: size.height - 2))
            tailPath.addLine(to: CGPoint(x: 7, y: 15))
            tailPath.addLine(to: CGPoint(x: 17, y: 15))
            tailPath.close()
            tailPath.fill()

            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: circleRect.insetBy(dx: 6, dy: 6))
        }
    }
}
#endif
