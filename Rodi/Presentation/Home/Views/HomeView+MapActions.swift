//
//  HomeView+MapActions.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension HomeView {
    func handleMapEvent(_ event: RodiMapEvent) {
        switch event {
        case .ready:
            handleMapReady()
        case .markerTap(let markerID):
            handleMapMarkerTap(markerID)
        case .viewportChanged(let center, let zoomLevel, let viewport, let isUserInitiated):
            handleMapViewportChange(
                center: center,
                zoomLevel: zoomLevel,
                viewport: viewport,
                isUserInitiated: isUserInitiated
            )
        case .cameraMoveFinished(let requestID):
            handleCameraMoveFinished(requestID: requestID)
        case .failed(let message):
            handleMapLoadingFailure(message)
        }
    }

    func handleMapReady() {
        homeStore.send(.mapAction(.ready))
        runtimeService.markMapReady()
        runtimeService.renderInitialMapMarkers(for: homeStore.state.visibleItems)
        consumePendingPlaceSelectionIfNeeded()
    }

    func handleMapViewportChange(
        center: RodiCoordinate,
        zoomLevel: Int,
        viewport: PlaceViewport,
        isUserInitiated: Bool
    ) {
        homeStore.send(
            .mapAction(
                .viewportChanged(
                    center: center,
                    zoomLevel: zoomLevel,
                    viewport: viewport,
                    isUserInitiated: isUserInitiated
                )
            )
        )
        homeStore.send(
            .placeListAction(
                .viewportChanged(
                    viewport: viewport,
                    center: center,
                    isUserInitiated: isUserInitiated
                )
            )
        )
        runtimeService.updateMapViewport(center: center, zoomLevel: zoomLevel)
        runtimeService.updateMapMarkersForViewportIfNeeded(for: homeStore.state.visibleItems)
    }

    func handleCameraMoveFinished(requestID: Int) {
        homeStore.send(.mapAction(.cameraMoveFinished(requestID: requestID)))
        runtimeService.markCameraMoveFinished(requestID: requestID)
    }

    func handleMapLoadingFailure(_ message: String) {
        homeStore.send(.mapAction(.loadingFailed(message)))
        runtimeService.failMapLoading(message: message)
    }

    func retryMapLoadingFromNetworkError() {
        homeStore.send(.mapAction(.retryLoading))
    }
}
