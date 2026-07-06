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
        case .viewportChanged(let center, let zoomLevel):
            handleMapViewportChange(center: center, zoomLevel: zoomLevel)
        case .cameraMoveFinished(let requestID):
            handleCameraMoveFinished(requestID: requestID)
        case .failed(let message):
            handleMapLoadingFailure(message)
        }
    }

    func handleMapReady() {
        homeStore.send(.mapAction(.ready))
        runtimeService.markMapReady()
        runtimeService.renderMapMarkers(for: homeStore.state.visibleItems)
    }

    func handleMapViewportChange(center: RodiCoordinate, zoomLevel: Int) {
        homeStore.send(.mapAction(.viewportChanged(center: center, zoomLevel: zoomLevel)))
        runtimeService.updateMapViewport(center: center, zoomLevel: zoomLevel)
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
