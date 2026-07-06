//
//  RodiMapCameraController.swift
//  Rodi
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func moveCamera(to coordinate: RodiCoordinate, requestID: Int, animated: Bool) {
        guard let map = kakaoMap else { return }
        lastAppliedCameraRequestID = requestID
        let level = cameraLevel(for: map, animated: animated, focus: latestCameraFocus)
        let cameraTarget = adjustedCameraTarget(for: coordinate, level: level)
        RodiLogger.debug("Kakao map moveCamera requestID=\(requestID), center=\(RodiLogger.coordinate(cameraTarget)), original=\(RodiLogger.coordinate(coordinate)), level=\(level), currentLevel=\(map.zoomLevel), animated=\(animated), focus=\(latestCameraFocus), bottomInset=\(latestCameraBottomInset)")
        let point = MapPoint(longitude: cameraTarget.longitude, latitude: cameraTarget.latitude)
        let update = CameraUpdate.make(target: point, zoomLevel: level, mapView: map)

        if animated {
            let options = CameraAnimationOptions(
                autoElevation: true,
                consecutive: false,
                durationInMillis: Constants.focusAnimationDurationMillis
            )
            map.animateCamera(cameraUpdate: update, options: options) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        } else {
            map.moveCamera(update) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        }
    }

    func adjustedCameraTarget(for coordinate: RodiCoordinate, level: Int) -> RodiCoordinate {
        guard (latestCameraFocus == .closeSingleLocation || latestCameraFocus == .currentLocation),
              latestCameraBottomInset > 0,
              bounds.height > latestCameraBottomInset
        else {
            return coordinate
        }

        let markerYOffset = max((latestCameraBottomInset / 2) - selectedMarkerVisualCenterOffset(for: latestCameraFocus), 0)
        let metersPerPixel = metersPerPixel(latitude: coordinate.latitude, zoomLevel: level)
        let latitudeOffset = metersToLatitudeDegrees(markerYOffset * metersPerPixel)

        return RodiCoordinate(
            latitude: coordinate.latitude - latitudeOffset,
            longitude: coordinate.longitude
        )
    }

    func selectedMarkerVisualCenterOffset(for focus: RodiMapCameraFocus) -> CGFloat {
        guard focus == .closeSingleLocation,
              latestMapMarkers.count == 1,
              latestMapMarkers[0].kind == .parking
        else {
            return 0
        }

        return Constants.parkingMarkerVisualHeight / 2
    }

    func metersPerPixel(latitude: Double, zoomLevel: Int) -> Double {
        let earthCircumferenceMeters = 156_543.03392
        return earthCircumferenceMeters * cos(latitude * .pi / 180) / pow(2, Double(zoomLevel))
    }

    func metersToLatitudeDegrees(_ meters: Double) -> Double {
        meters / 111_320
    }

    func cameraLevel(for map: KakaoMap, animated: Bool, focus: RodiMapCameraFocus) -> Int {
        if focus == .koreaOverview {
            return min(max(Constants.koreaOverviewLevel, map.minLevel), map.maxLevel)
        }

        if focus == .closeSingleLocation {
            return min(max(Constants.closeSingleLocationLevel, map.minLevel), map.maxLevel)
        }

        guard animated else { return Constants.mapLevel }

        let currentLevel = map.zoomLevel
        let oneKilometerLevel = min(Constants.oneKilometerFocusLevel, map.maxLevel)
        let targetLevel = max(currentLevel, oneKilometerLevel)
        return min(max(targetLevel, map.minLevel), map.maxLevel)
    }
}
#endif
