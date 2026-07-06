//
//  HomeRuntimeService+LocationDelegate.swift
//  Rodi
//

import CoreLocation

extension HomeRuntimeService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorizationStatus = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }

            RodiLogger.info("Location authorization changed status=\(authorizationStatus.rawValue)")
            applyAuthorizationStatus(authorizationStatus, reason: "delegate_changed")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let horizontalAccuracy = location.horizontalAccuracy

        Task { @MainActor [weak self] in
            guard let self else { return }
            let requestKind = pendingLocationRequest
            let requestID = activeLocationRequestID
            pendingLocationRequest = .initial
            applyLocationCoordinate(
                latitude: latitude,
                longitude: longitude,
                horizontalAccuracy: horizontalAccuracy,
                requestKind: requestKind,
                requestID: requestID
            )
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errorDescription = error.localizedDescription
        Task { @MainActor [weak self] in
            guard let self else { return }
            let requestKind = pendingLocationRequest
            let requestID = activeLocationRequestID
            pendingLocationRequest = .initial
            RodiLogger.warning("Location request failed: \(errorDescription)")
            if requestKind == .userInitiated {
                emit(.locationNoticeRequested("현재 위치를 찾지 못했어요."))
            }
            useFallbackLocation(reason: "location_request_failed", shouldMoveCamera: requestKind == .userInitiated, requestKind: requestKind, requestID: requestID)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading
        let magneticHeading = newHeading.magneticHeading
        let headingAccuracy = newHeading.headingAccuracy

        Task { @MainActor [weak self] in
            guard let self else { return }
            let heading = trueHeading >= 0 ? trueHeading : magneticHeading
            guard heading >= 0 else { return }
            setUserHeadingDegrees(heading)
            let source = trueHeading >= 0 ? "trueHeading" : "magneticHeading"
            RodiLogger.debug("Heading update source=\(source), degrees=\(heading), true=\(trueHeading), magnetic=\(magneticHeading), accuracy=\(headingAccuracy)")
        }
    }
}
