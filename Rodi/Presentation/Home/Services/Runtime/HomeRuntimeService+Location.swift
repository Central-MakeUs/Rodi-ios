//
//  HomeRuntimeService+Location.swift
//  Rodi
//

import CoreLocation
import SwiftUI

extension HomeRuntimeService {
    func applyLocationCoordinate(
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: CLLocationAccuracy,
        requestKind: LocationRequestKind,
        requestID: Int?
    ) {
        guard shouldAcceptLocationUpdate(requestID: requestID) else {
            RodiLogger.debug("Ignoring stale location update requestID=\(requestID.map(String.init) ?? "nil"), active=\(activeLocationRequestID.map(String.init) ?? "nil")")
            return
        }

        let coordinate = RodiCoordinate(
            latitude: latitude,
            longitude: longitude
        )
        logStartupTrace(
            "location_received",
            detail: "kind=\(requestKind.logValue), requestID=\(requestID.map(String.init) ?? "nil"), accuracy=\(horizontalAccuracy), coordinate=\(RodiLogger.coordinate(coordinate))"
        )
        RodiLogger.info(
            "Location update kind=\(requestKind.logValue), permission=\(locationManager.authorizationStatus.rawValue), raw=\(RodiLogger.coordinate(coordinate)), accuracy=\(horizontalAccuracy)"
        )

        guard HomeLocationPolicy.isSupportedServiceCoordinate(coordinate) else {
            RodiLogger.warning("Location outside Korea bounds. raw=\(RodiLogger.coordinate(coordinate)), using fallback map")
            if requestKind == .userInitiated {
                emit(.locationNoticeRequested("현재 위치가 서비스 지원 지역 밖이에요."))
            }
            useFallbackLocation(reason: "outside_korea_bounds", shouldMoveCamera: requestKind == .userInitiated, requestKind: requestKind, requestID: requestID)
            return
        }

        lastValidUserCoordinate = coordinate
        isUsingFallbackLocation = false
        setUserLocationCoordinate(coordinate)
        let shouldMoveExistingMap = shouldMoveCameraForLocationUpdate(requestKind: requestKind)
        prepareMapRendering(
            center: coordinate,
            userLocation: coordinate,
            reason: requestKind.logValue,
            animated: shouldMoveExistingMap && (requestKind == .userInitiated || isMapViewReady),
            shouldMoveExistingMap: shouldMoveExistingMap,
            focus: requestKind == .userInitiated ? .currentLocation : .normal
        )
        if !shouldMoveExistingMap {
            logStartupTrace(
                "late_location_camera_move_suppressed",
                detail: "kind=\(requestKind.logValue)"
            )
        }
        if requestKind == .initial {
            prepareInitialPlaceListSearch(origin: coordinate)
        }
        finishLocationResolution(requestKind: requestKind, requestID: requestID)
    }

    func moveCamera(
        to coordinate: RodiCoordinate,
        reason: String,
        animated: Bool = false,
        focus: RodiMapCameraFocus = .normal
    ) {
        let requestID = nextCameraRequest()
        mapViewport = RodiMapViewport(center: coordinate, zoomLevel: HomeMapCameraPolicy.zoomLevel(for: focus))
        emitCameraState(
            target: coordinate,
            requestID: requestID,
            animatedRequestID: animated ? requestID : nil,
            focus: focus
        )
        RodiLogger.info(
            "Camera request id=\(requestID), reason=\(reason), target=\(RodiLogger.coordinate(coordinate)), animated=\(animated), focus=\(focus)"
        )
    }

    func prepareMapRendering(
        center: RodiCoordinate,
        userLocation: RodiCoordinate?,
        reason: String,
        animated: Bool,
        shouldMoveExistingMap: Bool = true,
        focus: RodiMapCameraFocus = .normal
    ) {
        setUserLocationCoordinate(userLocation)

        if hasRequestedMapRendering {
            if isMapViewReady {
                emit(.mapLoadingChanged(false))
            }
            if shouldMoveExistingMap {
                moveCamera(to: center, reason: reason, animated: animated, focus: focus)
            } else {
                RodiLogger.info(
                    "Map camera move skipped for existing map reason=\(reason), userMarkerVisible=\(userLocation != nil)"
                )
            }
            return
        }

        let requestID = nextCameraRequest()
        mapViewport = RodiMapViewport(center: center, zoomLevel: HomeMapCameraPolicy.zoomLevel(for: focus))
        emitCameraState(
            target: center,
            requestID: requestID,
            animatedRequestID: nil,
            focus: focus
        )
        setMapRenderingRequested(true)
        emit(.mapLoadingChanged(true))
        logStartupTrace(
            "should_render_map_true",
            detail: "reason=\(reason), cameraRequestID=\(requestID), center=\(RodiLogger.coordinate(center)), userMarkerVisible=\(userLocation != nil)"
        )
        RodiLogger.info(
            "Map rendering enabled after location decision id=\(requestID), reason=\(reason), center=\(RodiLogger.coordinate(center)), userMarkerVisible=\(userLocation != nil)"
        )
    }

    func logStartupTrace(_ event: String, detail: String? = nil) {
        let elapsed = Date().timeIntervalSince(startupTraceStartDate)
        let suffix = detail.map { ", \($0)" } ?? ""
        RodiLogger.info(String(format: "Home startup %@ elapsed=%.3fs%@", event, elapsed, suffix))
    }
}
