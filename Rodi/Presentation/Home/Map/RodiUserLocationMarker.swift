//
//  RodiUserLocationMarker.swift
//  Rodi
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func updateUserLocationMarker(animatedHeading: Bool) {
        guard let map = kakaoMap else { return }

        guard let coordinate = latestUserLocation else {
            removeUserLocationMarker()
            return
        }

        let point = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
        if let userLocationPoi {
            userLocationPoi.moveAt(point, duration: 0)
            userDirectionFanPoi?.moveAt(point, duration: 0)
            updateUserDirectionMarkerOrientation(animated: animatedHeading)
            RodiLogger.debug("Kakao user location marker moved coordinate=\(RodiLogger.coordinate(coordinate))")
            return
        }

        let manager = map.getLabelManager()
        registerUserLocationStyleIfNeeded(with: manager)

        if userLocationLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.userLocationLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 10_000
            )
            userLocationLayer = manager.addLabelLayer(option: options)
        }

        if userDirectionLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.userDirectionLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 9_999
            )
            userDirectionLayer = manager.addLabelLayer(option: options)
        }

        guard let locationLayer = userLocationLayer, let directionLayer = userDirectionLayer else {
            RodiLogger.warning("Kakao user location layer creation failed")
            return
        }

        let locationOptions = PoiOptions(
            styleID: Constants.userLocationStyleID,
            poiID: Constants.userLocationPoiID
        )
        locationOptions.rank = 1
        locationOptions.transformType = .decal

        guard let locationPoi = locationLayer.addPoi(option: locationOptions, at: point) else {
            RodiLogger.warning("Kakao user location marker unavailable")
            return
        }

        let fanOptions = PoiOptions(
            styleID: Constants.userDirectionFanStyleID,
            poiID: Constants.userDirectionFanPoiID
        )
        fanOptions.rank = 2
        fanOptions.transformType = .absoluteRotationDecal

        let fanPoi = directionLayer.addPoi(option: fanOptions, at: point)
        if fanPoi == nil {
            RodiLogger.warning("Kakao user direction fan marker unavailable")
        }

        userLocationPoi = locationPoi
        userDirectionFanPoi = fanPoi

        if let fanPoi {
            fanPoi.show()
        }
        updateUserDirectionMarkerOrientation(animated: false)
        locationPoi.show()
        RodiLogger.info("Kakao user location marker shown coordinate=\(RodiLogger.coordinate(coordinate))")
    }

    func shouldAnimateHeadingChange(from previousHeading: Double?, to nextHeading: Double?) -> Bool {
        guard let previousHeading, let nextHeading else { return false }
        let rawDifference = abs(previousHeading - nextHeading).truncatingRemainder(dividingBy: 360)
        let shortestDifference = min(rawDifference, 360 - rawDifference)
        return shortestDifference >= 0.5
    }

    func removeUserLocationMarker() {
        var didRemoveMarker = false
        if userLocationPoi != nil {
            userLocationLayer?.removePoi(poiID: Constants.userLocationPoiID)
            userLocationPoi = nil
            didRemoveMarker = true
        }
        if userDirectionFanPoi != nil {
            userDirectionLayer?.removePoi(poiID: Constants.userDirectionFanPoiID)
            userDirectionFanPoi = nil
            didRemoveMarker = true
        }
        if didRemoveMarker {
            RodiLogger.debug("Kakao user location marker removed")
        }
    }

    func updateUserDirectionMarkerOrientation(animated: Bool) {
        guard let heading = latestUserHeadingDegrees, let userDirectionFanPoi else { return }
        let radians = heading * .pi / 180
        if animated {
            userDirectionFanPoi.rotateAt(radians, duration: 180)
        } else {
            userDirectionFanPoi.orientation = radians
        }
        RodiLogger.debug("Kakao user direction marker heading=\(heading), radians=\(radians)")
    }

    func registerUserLocationStyleIfNeeded(with manager: LabelManager) {
        guard !didRegisterUserLocationStyle else { return }

        let locationImage = makeUserLocationMarkerImage()
        let iconStyle = PoiIconStyle(symbol: locationImage, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        let locationStyle = PoiStyle(
            styleID: Constants.userLocationStyleID,
            styles: [PerLevelPoiStyle(iconStyle: iconStyle, level: 0)]
        )
        manager.addPoiStyle(locationStyle)

        let fanImage = makeOrbitingDirectionFanImage(
            from: makeUserDirectionMarkerImage(),
            bodySize: CGSize(
                width: Constants.userLocationMarkerDiameter,
                height: Constants.userLocationMarkerDiameter
            )
        )
        let fanIconStyle = PoiIconStyle(symbol: fanImage, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        let fanStyle = PoiStyle(
            styleID: Constants.userDirectionFanStyleID,
            styles: [PerLevelPoiStyle(iconStyle: fanIconStyle, level: 0)]
        )
        manager.addPoiStyle(fanStyle)

        didRegisterUserLocationStyle = true
        RodiLogger.info("Kakao user location marker style registered")
    }

}
#endif
