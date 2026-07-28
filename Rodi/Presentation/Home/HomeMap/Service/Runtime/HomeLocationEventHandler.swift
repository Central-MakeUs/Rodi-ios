//
//  HomeLocationEventHandler.swift
//  Rodi
//

import CoreLocation

extension HomeMapRuntimeService {
    func handleLocationUpdate(_ locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let horizontalAccuracy = location.horizontalAccuracy

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

    func handleLocationFailure(_ error: Error) {
        let errorDescription = error.localizedDescription
        let requestKind = pendingLocationRequest
        let requestID = activeLocationRequestID
        pendingLocationRequest = .initial
        RodiLogger.warning("Location request failed: \(errorDescription)")
        if requestKind == .userInitiated {
            emit(.locationNoticeRequested("현재 위치를 찾지 못했어요."))
        }
        useFallbackLocation(reason: "location_request_failed", shouldMoveCamera: requestKind == .userInitiated, requestKind: requestKind, requestID: requestID)
    }

    func handleHeadingUpdate(_ newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading
        let magneticHeading = newHeading.magneticHeading
        let headingAccuracy = newHeading.headingAccuracy

        let heading = trueHeading >= 0 ? trueHeading : magneticHeading
        guard heading >= 0 else { return }
        setUserHeadingDegrees(heading)
        let source = trueHeading >= 0 ? "trueHeading" : "magneticHeading"
        RodiLogger.debug("Heading update source=\(source), degrees=\(heading), true=\(trueHeading), magnetic=\(magneticHeading), accuracy=\(headingAccuracy)")
    }
}
