//
//  HomeMapRuntimeService.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import CoreLocation
import Combine
import Foundation

@MainActor
final class HomeMapRuntimeService: NSObject, ObservableObject {
    var onEvent: ((HomeRuntimeEvent) -> Void)?

    private var nextCameraRequestID = 0

    // Runtime-only caches used for location decisions. UI state lives in HomeReducer.State.
    private(set) var latestUserLocationCoordinate: RodiCoordinate?

    var hasLocationPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    var isResolvingCurrentLocation = false

    // Runtime lifecycle flags. HomeReducer.State remains the rendering source of truth.
    private(set) var hasRequestedMapRendering = false
    private(set) var renderedMarkerCount = 0
    var lastAppliedMarkerTier: RodiHomeMarkerClusterIndex.Tier?
    var lastRequestedMarkerSnapshot: [RodiMapMarker] = []
    var forcedMarkerTier: RodiHomeMarkerClusterIndex.Tier?
    var forcedMarkerZoomLevel: Int?

    let markerRenderingService = HomeMarkerRenderingService()
    let locationService = HomeLocationService()
    var locationManager: CLLocationManager { locationService.manager }
    let startupTraceStartDate = Date()
    var pendingLocationRequest: LocationRequestKind = .initial
    var isMapViewReady = false
    var lastValidUserCoordinate: RodiCoordinate?
    var didUseInitialFallbackLocation = false
    var isUsingFallbackLocation = false
    var locationResolutionID = 0
    var activeLocationRequestID: Int?
    var authorizationFallbackTask: Task<Void, Never>?
    var locationResolutionTimeoutTask: Task<Void, Never>?
    var fallbackRecenterTask: Task<Void, Never>?
    var mapViewport = RodiMapViewport.initial
    var didShowDeniedLocationPermissionAlert = false
    var didRequestSystemLocationAuthorizationThisSession = false
    var didPrepareInitialPlaceListSearch = false

    override init() {
        super.init()
        logStartupTrace("runtime_service_init")
        locationService.onAuthorizationChanged = { [weak self] status in
            guard let self else { return }
            RodiLogger.info("Location authorization changed status=\(status.rawValue)")
            self.applyAuthorizationStatus(status, reason: "delegate_changed")
        }
        locationService.onLocationsUpdated = { [weak self] locations in
            self?.handleLocationUpdate(locations)
        }
        locationService.onFailure = { [weak self] error in
            self?.handleLocationFailure(error)
        }
        locationService.onHeadingUpdated = { [weak self] heading in
            self?.handleHeadingUpdate(heading)
        }
    }

    func start(onEvent: @escaping (HomeRuntimeEvent) -> Void) {
        guard self.onEvent == nil else { return }
        self.onEvent = onEvent
        locationService.activate()
        bootstrapLocation()
    }

    func stop() {
        authorizationFallbackTask?.cancel()
        authorizationFallbackTask = nil
        locationResolutionTimeoutTask?.cancel()
        locationResolutionTimeoutTask = nil
        fallbackRecenterTask?.cancel()
        fallbackRecenterTask = nil
        markerRenderingService.cancel()
        locationService.stop()
        onEvent = nil
        RodiLogger.info("Home runtime service stopped")
    }

    deinit {
        authorizationFallbackTask?.cancel()
        locationResolutionTimeoutTask?.cancel()
        fallbackRecenterTask?.cancel()
    }

}

extension HomeMapRuntimeService {
    func emit(_ event: HomeRuntimeEvent) {
        onEvent?(event)
    }

    func emitCameraState(
        target: RodiCoordinate,
        requestID: Int,
        animatedRequestID: Int?,
        focus: RodiMapCameraFocus
    ) {
        emit(.cameraStateChanged(
            target: target,
            requestID: requestID,
            animatedRequestID: animatedRequestID,
            focus: focus
        ))
    }

    func setUserLocationCoordinate(_ coordinate: RodiCoordinate?) {
        latestUserLocationCoordinate = coordinate
        emit(.userLocationCoordinateChanged(coordinate))
    }

    func setUserHeadingDegrees(_ degrees: Double?) {
        emit(.userHeadingDegreesChanged(degrees))
    }

    func setMapRenderingRequested(_ isRequested: Bool) {
        guard hasRequestedMapRendering != isRequested else { return }
        hasRequestedMapRendering = isRequested
        emit(.shouldRenderMapChanged(isRequested))
    }

    func emitLocationPermissionState() {
        emit(.locationPermissionChanged(hasLocationPermission))
    }

    func setCurrentLocationButtonActive(_ isActive: Bool) {
        emit(.currentLocationButtonActiveChanged(isActive))
    }

    func prepareInitialPlaceListSearch(origin: RodiCoordinate) {
        guard !didPrepareInitialPlaceListSearch else { return }
        didPrepareInitialPlaceListSearch = true
        emit(.initialPlaceListSearchPrepared(origin))
    }

    func setRenderedMapMarkers(_ markers: [RodiMapMarker]) {
        renderedMarkerCount = markers.count
        emit(.renderedMapMarkersChanged(markers))
    }

    func nextCameraRequest() -> Int {
        nextCameraRequestID += 1
        return nextCameraRequestID
    }

    func synchronizeCameraRequestID(minimum requestID: Int) {
        guard nextCameraRequestID < requestID else { return }
        nextCameraRequestID = requestID
        RodiLogger.debug("Runtime camera request id synchronized minimum=\(requestID)")
    }
}
