//
//  HomeRuntimeService.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import CoreLocation
import Combine
import Foundation

@MainActor
final class HomeRuntimeService: NSObject, ObservableObject {
    var onEvent: ((HomeRuntimeEvent) -> Void)?

    private var nextCameraRequestID = 0

    // Runtime-only caches used for location decisions. UI state lives in HomeState.
    private(set) var latestUserLocationCoordinate: RodiCoordinate?

    var hasLocationPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    var isResolvingCurrentLocation = false

    // Runtime lifecycle flags. HomeState remains the rendering source of truth.
    private(set) var hasRequestedMapRendering = false
    private(set) var renderedMarkerCount = 0

    let markerRenderingService = HomeMarkerRenderingService()
    let locationManager = CLLocationManager()
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

    override init() {
        super.init()
        logStartupTrace("runtime_service_init")
        locationManager.delegate = self
        locationManager.desiredAccuracy = HomeLocationPolicy.accuracy(for: .initial)
        locationManager.headingFilter = 5
    }

    func start(onEvent: @escaping (HomeRuntimeEvent) -> Void) {
        guard self.onEvent == nil else { return }
        self.onEvent = onEvent
        locationManager.delegate = self
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
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        locationManager.delegate = nil
        onEvent = nil
        RodiLogger.info("Home runtime service stopped")
    }

    deinit {
        authorizationFallbackTask?.cancel()
        locationResolutionTimeoutTask?.cancel()
        fallbackRecenterTask?.cancel()
    }

}

extension HomeRuntimeService {
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

    func emitFilterAnchorCoordinate() {
        emit(.filterAnchorCoordinateChanged(filterAnchorCoordinate))
    }

    func setUserLocationCoordinate(_ coordinate: RodiCoordinate?) {
        latestUserLocationCoordinate = coordinate
        emit(.userLocationCoordinateChanged(coordinate))
        emitFilterAnchorCoordinate()
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
