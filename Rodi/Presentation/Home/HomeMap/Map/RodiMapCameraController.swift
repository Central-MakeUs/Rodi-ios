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
        markProgrammaticViewportChange(requestID: requestID)

        if case let .cluster(coordinates) = latestCameraFocus {
            focusClusterArea(coordinates, requestID: requestID, animated: animated)
            return
        }

        if case let .administrativeArea(areaBounds) = latestCameraFocus {
            focusAdministrativeArea(areaBounds, requestID: requestID, animated: animated)
            return
        }

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

    /// cluster drill-down에서는 다음 단계의 모든 marker가 보이도록 area fitting 카메라를 사용한다.
    func focusClusterArea(
        _ coordinates: [RodiCoordinate],
        requestID: Int,
        animated: Bool
    ) {
        guard let map = kakaoMap, !coordinates.isEmpty else { return }

        guard coordinates.count > 1 else {
            let coordinate = coordinates[0]
            let point = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
            let level = min(max(Constants.oneKilometerFocusLevel, map.minLevel), map.maxLevel)
            let update = CameraUpdate.make(target: point, zoomLevel: level, mapView: map)
            applyClusterCamera(update, requestID: requestID, animated: animated)
            return
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max()
        else {
            return
        }

        let latitudeSpan = max(maxLatitude - minLatitude, 0.008)
        let longitudeSpan = max(maxLongitude - minLongitude, 0.008)
        let bottomCoverageRatio = bounds.height > 0
            ? min(max(latestCameraBottomInset / bounds.height, 0), 0.7)
            : 0
        let bottomPadding = 0.25 + bottomCoverageRatio * 1.2
        let topPadding = 0.18
        let horizontalPadding = 0.2
        let area = AreaRect(points: [
            MapPoint(
                longitude: minLongitude - longitudeSpan * horizontalPadding,
                latitude: minLatitude - latitudeSpan * bottomPadding
            ),
            MapPoint(
                longitude: maxLongitude + longitudeSpan * horizontalPadding,
                latitude: maxLatitude + latitudeSpan * topPadding
            )
        ])
        applyClusterCamera(
            CameraUpdate.make(area: area, levelLimit: -1),
            requestID: requestID,
            animated: animated
        )
    }

    func focusAdministrativeArea(
        _ areaBounds: RodiMapBounds,
        requestID: Int,
        animated: Bool
    ) {
        guard kakaoMap != nil else { return }

        let latitudeSpan = max(areaBounds.northEastLatitude - areaBounds.southWestLatitude, 0.008)
        let longitudeSpan = max(areaBounds.northEastLongitude - areaBounds.southWestLongitude, 0.008)
        let bottomCoverageRatio = bounds.height > 0
            ? min(max(latestCameraBottomInset / bounds.height, 0), 0.7)
            : 0
        let area = AreaRect(points: [
            MapPoint(
                longitude: areaBounds.southWestLongitude - longitudeSpan * 0.2,
                latitude: areaBounds.southWestLatitude - latitudeSpan * (0.25 + bottomCoverageRatio * 1.2)
            ),
            MapPoint(
                longitude: areaBounds.northEastLongitude + longitudeSpan * 0.2,
                latitude: areaBounds.northEastLatitude + latitudeSpan * 0.18
            )
        ])
        applyClusterCamera(
            CameraUpdate.make(area: area, levelLimit: -1),
            requestID: requestID,
            animated: animated
        )
    }

    private func applyClusterCamera(
        _ update: CameraUpdate,
        requestID: Int,
        animated: Bool
    ) {
        markProgrammaticViewportChange(requestID: requestID)
        if animated {
            let options = CameraAnimationOptions(
                autoElevation: true,
                consecutive: false,
                durationInMillis: Constants.focusAnimationDurationMillis
            )
            kakaoMap?.animateCamera(cameraUpdate: update, options: options) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        } else {
            kakaoMap?.moveCamera(update) { [weak self] in
                self?.coordinator?.reportCameraMoveFinished(requestID)
            }
        }
    }

    private func markProgrammaticViewportChange(requestID: Int) {
        pendingProgrammaticViewportRequestID = requestID
        programmaticViewportResetWorkItem?.cancel()

        let resetWorkItem = DispatchWorkItem { [weak self] in
            guard self?.pendingProgrammaticViewportRequestID == requestID else { return }
            self?.pendingProgrammaticViewportRequestID = nil
        }
        programmaticViewportResetWorkItem = resetWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: resetWorkItem)
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
