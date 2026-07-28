//
//  HomeMapCameraRuntime.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

extension HomeMapRuntimeService {
    /// 위치 권한 결과를 기다리지 않고 전국 지도와 공개 장소 좌표를 먼저 표시한다.
    func showInitialPlaceMapIfNeeded() {
        guard !hasRequestedMapRendering else { return }

        prepareMapRendering(
            center: .southKoreaCenter,
            userLocation: nil,
            reason: "place_coordinates_bootstrap",
            animated: false,
            focus: .koreaOverview
        )
    }

    func prepareForCurrentLocationRequest() {
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
        minimumCameraRequestID requestID: Int
    ) {
        prepareForCurrentLocationRequest()
        synchronizeCameraRequestID(minimum: requestID)
        requestCurrentLocation()
    }
}
