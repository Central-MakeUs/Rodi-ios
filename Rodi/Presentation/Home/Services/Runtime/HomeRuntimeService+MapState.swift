//
//  HomeRuntimeService+MapState.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

extension HomeRuntimeService {
    func prepareForCurrentLocationRequest(visibleItems: [RodiCourseItem]) {
        if renderedMarkerCount <= 1 {
            restartProgressiveMarkerRendering(for: visibleItems)
        }
        RodiLogger.info(
            "Runtime prepared for current location request viewportCenter=\(RodiLogger.coordinate(mapViewport.center)), markerCount=\(renderedMarkerCount)"
        )
    }

    func markCameraMoveFinished(requestID: Int) {
        RodiLogger.info("Camera move finished requestID=\(requestID). Store owns current location button state.")
    }

    func markMapReady() {
        isMapViewReady = true
        logStartupTrace("kakao_map_on_ready", detail: "locationResolving=\(isResolvingCurrentLocation)")
        RodiLogger.info("Home map ready. Location resolution continues separately=\(isResolvingCurrentLocation)")
        recenterFallbackMapIfNeeded()
    }

    func updateMapViewport(center: RodiCoordinate, zoomLevel: Int) {
        let nextViewport = RodiMapViewport(center: center, zoomLevel: zoomLevel)
        guard nextViewport != mapViewport else { return }

        mapViewport = nextViewport
        RodiLogger.info(
            "Home map viewport changed center=\(RodiLogger.coordinate(center)), zoomLevel=\(zoomLevel)"
        )
    }

    func failMapLoading(message: String) {
        RodiLogger.warning("Home map loading failed message=\(message)")
    }

    func requestCurrentLocationAfterStoreUpdate(
        minimumCameraRequestID requestID: Int,
        visibleItems: [RodiCourseItem]
    ) {
        prepareForCurrentLocationRequest(visibleItems: visibleItems)
        synchronizeCameraRequestID(minimum: requestID)
        requestCurrentLocation()
    }
}
