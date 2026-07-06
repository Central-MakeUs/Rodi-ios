//
//  RodiMapRouteStyles.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func registerRouteStylesIfNeeded(labelManager: LabelManager, shapeManager: ShapeManager) {
        guard !didRegisterRouteStyles else { return }

        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeStartMarkerStyleID, assetName: "ic_start_pin"))
        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeWaypointMarkerStyleID, assetName: "ic_parking_pin"))
        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeEndMarkerStyleID, assetName: "ic_arrival_pin"))

        let lineStyle = PerLevelPolylineStyle(
            bodyColor: UIColor(red: 0.337, green: 0.251, blue: 1.0, alpha: 1.0),
            bodyWidth: 8,
            strokeColor: UIColor.white.withAlphaComponent(0.85),
            strokeWidth: 3,
            level: 0
        )
        let style = PolylineStyle(styles: [lineStyle])
        let styleSet = PolylineStyleSet(styleSetID: Constants.routePolylineStyleID, styles: [style], capType: .round)
        shapeManager.addPolylineStyleSet(styleSet)

        didRegisterRouteStyles = true
    }

    func makeRouteMarkerStyle(styleID: String, assetName: String) -> PoiStyle {
        let image = UIImage(named: assetName) ?? makeFallbackRouteMarkerImage()
        let iconStyle = PoiIconStyle(symbol: image, anchorPoint: CGPoint(x: 0.5, y: 1.0))
        return PoiStyle(
            styleID: styleID,
            styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)]
        )
    }

    func markerStyleID(for role: RodiCoursePointRole) -> String {
        switch role {
        case .start:
            Constants.routeStartMarkerStyleID
        case .waypoint:
            Constants.routeWaypointMarkerStyleID
        case .end:
            Constants.routeEndMarkerStyleID
        }
    }

    func makeFallbackRouteMarkerImage() -> UIImage {
        let size = CGSize(width: 34, height: 42)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let pinRect = CGRect(x: 4, y: 2, width: 26, height: 26)
            UIColor(red: 0.337, green: 0.251, blue: 1.0, alpha: 1.0).setFill()
            context.cgContext.fillEllipse(in: pinRect)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: size.width / 2, y: size.height - 2))
            path.addLine(to: CGPoint(x: 9, y: 22))
            path.addLine(to: CGPoint(x: 25, y: 22))
            path.close()
            path.fill()

            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: pinRect.insetBy(dx: 8, dy: 8))
        }
    }
}
#endif
