//
//  RodiKakaoMapConfiguration.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func configure(
        cameraTarget: RodiCoordinate,
        cameraRequestID: Int,
        animatedCameraRequestID: Int?,
        cameraFocus: RodiMapCameraFocus,
        userLocation: RodiCoordinate?,
        userHeadingDegrees: Double?,
        routeOverlay: RodiRouteOverlay?,
        mapMarkers: [RodiMapMarker],
        logoBottomInset: CGFloat,
        cameraBottomInset: CGFloat,
        isInteractionEnabled: Bool,
        visibilityState: RodiMapVisibilityState,
        coordinator: KakaoMapContainerView.Coordinator
    ) {
        self.coordinator = coordinator
        latestCameraTarget = cameraTarget
        latestCameraRequestID = cameraRequestID
        latestAnimatedCameraRequestID = animatedCameraRequestID
        latestCameraFocus = cameraFocus
        latestUserLocation = userLocation
        latestUserHeadingDegrees = userHeadingDegrees
        latestRouteOverlay = routeOverlay
        latestMapMarkers = mapMarkers
        latestLogoBottomInset = logoBottomInset
        latestCameraBottomInset = cameraBottomInset
        latestVisibilityState = visibilityState
        RodiLogger.info(
            "Kakao map configure cameraTarget=\(RodiLogger.coordinate(cameraTarget)), userLocation=\(userLocation.logDescription), cameraRequestID=\(cameraRequestID), animatedCameraRequestID=\(animatedCameraRequestID.map(String.init) ?? "nil"), interaction=\(isInteractionEnabled), visibility=\(visibilityState)"
        )

        let controller = KMController(viewContainer: mapContainer)
        controller.delegate = coordinator
        coordinator.attach(mapView: self)
        mapController = controller
        didCreateController = true

        update(
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocation,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: routeOverlay,
            mapMarkers: mapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState
        )
        startEngineIfPossible(reason: "configure")
    }

    func update(
        cameraTarget: RodiCoordinate,
        cameraRequestID: Int,
        animatedCameraRequestID: Int?,
        cameraFocus: RodiMapCameraFocus,
        userLocation: RodiCoordinate?,
        userHeadingDegrees: Double?,
        routeOverlay: RodiRouteOverlay?,
        mapMarkers: [RodiMapMarker],
        logoBottomInset: CGFloat,
        cameraBottomInset: CGFloat,
        isInteractionEnabled: Bool,
        visibilityState: RodiMapVisibilityState
    ) {
        let renderInput = RenderInput(
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocation,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: routeOverlay,
            mapMarkers: mapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState
        )

        guard lastAppliedRenderInput != renderInput else { return }
        lastAppliedRenderInput = renderInput

        let previousUserLocation = latestUserLocation
        let previousHeadingDegrees = latestUserHeadingDegrees
        let didUserLocationChange = previousUserLocation != userLocation
        let didUserHeadingChange = previousHeadingDegrees != userHeadingDegrees
        latestCameraTarget = cameraTarget
        latestCameraRequestID = cameraRequestID
        latestAnimatedCameraRequestID = animatedCameraRequestID
        latestCameraFocus = cameraFocus
        latestUserLocation = userLocation
        latestUserHeadingDegrees = userHeadingDegrees
        let previousRouteOverlay = latestRouteOverlay
        latestRouteOverlay = routeOverlay
        latestMapMarkers = mapMarkers
        latestLogoBottomInset = logoBottomInset
        latestCameraBottomInset = cameraBottomInset
        latestVisibilityState = visibilityState

        let isMapActive = visibilityState.isActive && isApplicationActive
        let allowsMapInteraction = isMapActive && isInteractionEnabled
        isUserInteractionEnabled = allowsMapInteraction
        kakaoMap?.isEnabled = isMapActive
        applyGestureState(allowsMapInteraction)

        guard isMapActive else {
            pauseEngineIfNeeded(reason: "covered_update")
            return
        }

        startEngineIfPossible(reason: "active_update")
        activateEngineIfNeeded()
        updateLogoPosition()
        if didUserLocationChange || didUserHeadingChange {
            updateUserLocationMarker(
                animatedHeading: shouldAnimateHeadingChange(
                    from: previousHeadingDegrees,
                    to: userHeadingDegrees
                )
            )
        }
        updateHomeMarkers(with: mapMarkers)
        if previousRouteOverlay != routeOverlay {
            updateRouteOverlay()
        }

        if lastAppliedCameraRequestID != cameraRequestID {
            moveCamera(
                to: cameraTarget,
                requestID: cameraRequestID,
                animated: animatedCameraRequestID == cameraRequestID
            )
        }
    }
}
#endif
