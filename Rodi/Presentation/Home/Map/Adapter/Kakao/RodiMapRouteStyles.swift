//
//  RodiMapRouteStyles.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit
import SwiftUI

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    private enum RouteMarkerLayout {
        static let size = CGSize(width: 66, height: 66)
        // SVG의 실제 핀 꼭지점은 캔버스 맨 아래보다 1.5pt 위에 있다.
        // 꼭지점이 좌표에 정확히 닿도록 anchor를 그 위치에 맞춘다.
        static let tipAnchorPoint = CGPoint(x: 0.5, y: 32.5 / 34)
    }

    func registerRouteStylesIfNeeded(labelManager: LabelManager, shapeManager: ShapeManager) {
        guard !didRegisterRouteStyles else { return }

        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeStartMarkerStyleID, assetName: "ic_start_pin"))
        labelManager.addPoiStyle(makeRouteWaypointMarkerStyle())
        labelManager.addPoiStyle(makeRouteMarkerStyle(styleID: Constants.routeEndMarkerStyleID, assetName: "ic_arrival_pin"))

        let lineStyle = PerLevelPolylineStyle(
            bodyColor: UIColor(red: 0.337, green: 0.251, blue: 1.0, alpha: 1.0),
            bodyWidth: 12,
            strokeColor: UIColor(RodiColor.primary800),
            strokeWidth: 2,
            level: 0
        )
        let style = PolylineStyle(styles: [lineStyle])
        let styleSet = PolylineStyleSet(styleSetID: Constants.routePolylineStyleID, styles: [style], capType: .round)
        shapeManager.addPolylineStyleSet(styleSet)

        didRegisterRouteStyles = true
    }

    func makeRouteMarkerStyle(styleID: String, assetName: String) -> PoiStyle {
        let image = routeMarkerImage(assetName: assetName)
        let iconStyle = PoiIconStyle(symbol: image, anchorPoint: RouteMarkerLayout.tipAnchorPoint)
        return PoiStyle(
            styleID: styleID,
            styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)]
        )
    }

    func makeRouteWaypointMarkerStyle() -> PoiStyle {
        let image = routeMarkerImage(assetName: "ic_route_waypoint")
        let iconStyle = PoiIconStyle(symbol: image, anchorPoint: RouteMarkerLayout.tipAnchorPoint)
        return PoiStyle(
            styleID: Constants.routeWaypointMarkerStyleID,
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
        let size = RouteMarkerLayout.size
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

    func routeMarkerImage(assetName: String) -> UIImage {
        guard let asset = UIImage(named: assetName) else {
            return makeFallbackRouteMarkerImage()
        }

        let format = UIGraphicsImageRendererFormat.default()
        // Kakao 지도 SDK는 이미지의 실제 픽셀 크기로 POI를 표시하므로, 중앙 고정 핀과 균형이 맞는 크기로 정규화한다.
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: RouteMarkerLayout.size, format: format)
        return renderer.image { _ in
            asset.draw(in: CGRect(origin: .zero, size: RouteMarkerLayout.size))
        }
    }
}
#endif
