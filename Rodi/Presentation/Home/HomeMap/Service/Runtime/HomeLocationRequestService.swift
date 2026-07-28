//
//  HomeLocationRequestService.swift
//  Rodi
//

import CoreLocation
import Foundation

extension HomeMapRuntimeService {
    func requestCurrentLocation() {
        let authorizationStatus = locationManager.authorizationStatus
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            emitLocationPermissionState()
            RodiLogger.info("Current location request blocked: permission=\(authorizationStatus.rawValue)")
            requestLocationPermissionAlert(reason: "current_location_button")
            return
        }

        emitLocationPermissionState()
        if let lastValidUserCoordinate {
            setCurrentLocationButtonActive(true)
            RodiLogger.info(
                "Current location button using cached coordinate=\(RodiLogger.coordinate(lastValidUserCoordinate))"
            )
            moveCamera(to: lastValidUserCoordinate, reason: "user_initiated_cached", animated: true, focus: .currentLocation)
            isResolvingCurrentLocation = false
            return
        }

        setCurrentLocationButtonActive(true)
        RodiLogger.info("Current location requested by user permission=\(locationManager.authorizationStatus.rawValue)")
        requestLocation(kind: .userInitiated)
    }

    func requestLocation(kind: LocationRequestKind) {
        if kind == .initial, activeLocationRequestID != nil {
            RodiLogger.info("Initial location request skipped because request is already active id=\(activeLocationRequestID.map(String.init) ?? "nil")")
            return
        }

        pendingLocationRequest = kind
        isResolvingCurrentLocation = true
        if !hasRequestedMapRendering || !isMapViewReady {
            emit(.mapLoadingChanged(true))
        } else {
            emit(.mapLoadingChanged(false))
        }
        locationResolutionID += 1
        let requestID = locationResolutionID
        activeLocationRequestID = requestID
        let desiredAccuracy = HomeLocationPolicy.accuracy(for: kind)
        locationManager.desiredAccuracy = desiredAccuracy
        logStartupTrace(
            "request_location_started",
            detail: "kind=\(kind.logValue), requestID=\(requestID), desiredAccuracy=\(desiredAccuracy)"
        )
        RodiLogger.info("Location request started kind=\(kind.logValue), requestID=\(requestID), desiredAccuracy=\(desiredAccuracy)")
        locationManager.requestLocation()
        scheduleLocationResolutionTimeout(requestID: requestID, kind: kind)
    }

    func resetLocationRequestState(incrementID: Bool) {
        if incrementID {
            locationResolutionID += 1
        }
        activeLocationRequestID = nil
        pendingLocationRequest = .initial
        isResolvingCurrentLocation = false
        setCurrentLocationButtonActive(false)
        locationManager.stopUpdatingLocation()
    }

    func finishLocationResolution(requestKind: LocationRequestKind, requestID: Int?) {
        if let requestID, activeLocationRequestID == requestID {
            activeLocationRequestID = nil
        }
        isResolvingCurrentLocation = false
        RodiLogger.info("Location resolution finished kind=\(requestKind.logValue), mapReady=\(isMapViewReady)")
    }

    func scheduleLocationResolutionTimeout(requestID: Int, kind: LocationRequestKind) {
        locationResolutionTimeoutTask?.cancel()
        locationResolutionTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, locationResolutionID == requestID, isResolvingCurrentLocation else { return }
            RodiLogger.info("Location request still waiting kind=\(kind.logValue), requestID=\(requestID). Map rendering remains gated by location or fallback.")
            try? await Task.sleep(for: .seconds(1))
            guard locationResolutionID == requestID, isResolvingCurrentLocation else { return }

            switch kind {
            case .initial:
                useFallbackLocation(reason: "initial_location_timeout", shouldMoveCamera: false, requestKind: kind, requestID: requestID)
            case .userInitiated:
                setCurrentLocationButtonActive(false)
                isResolvingCurrentLocation = false
                if activeLocationRequestID == requestID {
                    activeLocationRequestID = nil
                }
                RodiLogger.info("Current location button reset after long user initiated location wait requestID=\(requestID)")
            }
            locationResolutionTimeoutTask = nil
        }
    }

    func shouldAcceptLocationUpdate(requestID: Int?) -> Bool {
        guard let requestID else { return hasLocationPermission }
        return activeLocationRequestID == requestID || activeLocationRequestID == nil
    }

    func shouldMoveCameraForLocationUpdate(requestKind: LocationRequestKind) -> Bool {
        guard requestKind == .initial, didUseInitialFallbackLocation, hasRequestedMapRendering else {
            return true
        }

        return false
    }
}
