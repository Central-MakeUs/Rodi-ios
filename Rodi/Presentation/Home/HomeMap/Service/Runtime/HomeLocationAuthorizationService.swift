//
//  HomeLocationAuthorizationService.swift
//  Rodi
//

import CoreLocation

extension HomeMapRuntimeService {
    func bootstrapLocation() {
        RodiLogger.info("Bootstrap location authorization=\(locationManager.authorizationStatus.rawValue)")
        applyAuthorizationStatus(locationManager.authorizationStatus, reason: "bootstrap")
    }

    func refreshLocationAuthorization() {
        let authorizationStatus = locationManager.authorizationStatus
        RodiLogger.info("Refresh location authorization status=\(authorizationStatus.rawValue), hasPermission=\(hasLocationPermission), fallback=\(isUsingFallbackLocation)")

        let isAuthorized = authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
        if isAuthorized, hasLocationPermission, !isUsingFallbackLocation {
            RodiLogger.info("Refresh location authorization skipped: already authorized and not in fallback")
            return
        }

        if (authorizationStatus == .denied || authorizationStatus == .restricted), !hasLocationPermission, isUsingFallbackLocation, hasRequestedMapRendering {
            RodiLogger.info("Refresh location authorization skipped: already using fallback")
            return
        }

        applyAuthorizationStatus(authorizationStatus, reason: "scene_active_refresh")
    }

    func applyAuthorizationStatus(_ authorizationStatus: CLAuthorizationStatus, reason: String) {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationFallbackTask?.cancel()
            authorizationFallbackTask = nil
            resetLocationRequestState(incrementID: false)
            emit(.mapErrorMessageChanged(nil))
            if hasRequestedMapRendering, isMapViewReady {
                emit(.mapLoadingChanged(false))
            }
            emitLocationPermissionState()
            didShowDeniedLocationPermissionAlert = false
            isUsingFallbackLocation = false
            didUseInitialFallbackLocation = false
            startHeadingUpdatesIfAvailable()
            RodiLogger.info("Location authorization applied: authorized reason=\(reason)")
            if shouldSkipDuplicateAuthorizedInitialRequest(reason: reason) {
                RodiLogger.info("Initial location request skipped: valid location already resolved reason=\(reason)")
                return
            }
            requestLocation(kind: .initial)
        case .notDetermined:
            resetLocationRequestState(incrementID: false)
            emitLocationPermissionState()
            isResolvingCurrentLocation = true
            emit(.mapLoadingChanged(true))
            RodiLogger.info("Location authorization applied: not_determined reason=\(reason)")
            didRequestSystemLocationAuthorizationThisSession = true
            locationManager.requestWhenInUseAuthorization()
            scheduleAuthorizationResolutionTimeout()
        case .denied, .restricted:
            authorizationFallbackTask?.cancel()
            authorizationFallbackTask = nil
            emitLocationPermissionState()
            RodiLogger.info("Location authorization applied: denied_or_restricted reason=\(reason)")
            useFallbackLocation(reason: "\(reason)_authorization_denied_or_restricted", shouldMoveCamera: true)
            if didRequestSystemLocationAuthorizationThisSession, reason == "delegate_changed" {
                didRequestSystemLocationAuthorizationThisSession = false
                didShowDeniedLocationPermissionAlert = true
                RodiLogger.info("Location permission alert suppressed after system authorization prompt denial.")
            } else {
                requestLocationPermissionAlertIfNeeded(reason: "\(reason)_authorization_denied_or_restricted")
            }
        @unknown default:
            authorizationFallbackTask?.cancel()
            authorizationFallbackTask = nil
            emitLocationPermissionState()
            RodiLogger.info("Location authorization applied: unknown reason=\(reason)")
            useFallbackLocation(reason: "\(reason)_authorization_unknown", shouldMoveCamera: true)
        }
    }

    func shouldSkipDuplicateAuthorizedInitialRequest(reason: String) -> Bool {
        guard activeLocationRequestID == nil else { return false }
        guard lastValidUserCoordinate != nil else { return false }
        guard hasRequestedMapRendering else { return false }
        return reason == "delegate_changed" || reason == "scene_active_refresh"
    }

    func requestLocationPermissionAlertIfNeeded(reason: String) {
        guard !didShowDeniedLocationPermissionAlert else { return }
        didShowDeniedLocationPermissionAlert = true
        requestLocationPermissionAlert(reason: reason)
    }

    func requestLocationPermissionAlert(reason: String) {
        emit(.locationPermissionAlertRequested)
        RodiLogger.info("Location permission alert requested reason=\(reason)")
    }

    func scheduleAuthorizationResolutionTimeout() {
        authorizationFallbackTask?.cancel()
        authorizationFallbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard let self else { return }
            guard locationManager.authorizationStatus == .notDetermined else { return }
            guard !hasRequestedMapRendering else { return }

            RodiLogger.info("Location authorization still not determined. Showing fallback map center.")
            useFallbackLocation(reason: "authorization_not_determined_timeout", shouldMoveCamera: false)
            authorizationFallbackTask = nil
        }
    }
}
