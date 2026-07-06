//
//  HomeRuntimeService+LocationFallback.swift
//  Rodi
//

import CoreLocation
import Foundation

extension HomeRuntimeService {
    func useFallbackLocation(
        reason: String,
        shouldMoveCamera: Bool,
        requestKind: LocationRequestKind = .initial,
        requestID: Int? = nil
    ) {
        if let requestID, !shouldAcceptLocationUpdate(requestID: requestID) {
            RodiLogger.debug("Ignoring stale fallback location requestID=\(requestID), active=\(activeLocationRequestID.map(String.init) ?? "nil")")
            return
        }

        logStartupTrace(
            "fallback_entered",
            detail: "reason=\(reason), kind=\(requestKind.logValue), requestID=\(requestID.map(String.init) ?? "nil"), shouldMoveCamera=\(shouldMoveCamera)"
        )
        if requestKind == .initial {
            didUseInitialFallbackLocation = true
        }
        authorizationFallbackTask?.cancel()
        authorizationFallbackTask = nil
        resetLocationRequestState(incrementID: requestID == nil)
        locationManager.stopUpdatingHeading()
        emit(.mapErrorMessageChanged(nil))
        emit(.selectionInvalidated)
        emit(.radiusFilterReset(.all))
        setRenderedMapMarkers([])
        markerRenderingService.cancel()
        setUserLocationCoordinate(nil)
        setUserHeadingDegrees(nil)
        lastValidUserCoordinate = nil
        isUsingFallbackLocation = true
        prepareMapRendering(
            center: .southKoreaCenter,
            userLocation: nil,
            reason: reason,
            animated: false,
            shouldMoveExistingMap: shouldMoveCamera,
            focus: .koreaOverview
        )
        finishLocationResolution(requestKind: requestKind, requestID: requestID)
        RodiLogger.info("Using fallback map center reason=\(reason), center=\(RodiLogger.coordinate(.southKoreaCenter)), permission=\(locationManager.authorizationStatus.rawValue), userMarkerVisible=false")
    }

    func recenterFallbackMapIfNeeded() {
        guard isUsingFallbackLocation, latestUserLocationCoordinate == nil else { return }

        fallbackRecenterTask?.cancel()
        fallbackRecenterTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, isUsingFallbackLocation, latestUserLocationCoordinate == nil else { return }
            moveCamera(to: .southKoreaCenter, reason: "fallback_map_ready_recenter", animated: false, focus: .koreaOverview)
            RodiLogger.info(
                "Fallback map recentered after Kakao map ready center=\(RodiLogger.coordinate(.southKoreaCenter))"
            )
            fallbackRecenterTask = nil
        }
    }
}
