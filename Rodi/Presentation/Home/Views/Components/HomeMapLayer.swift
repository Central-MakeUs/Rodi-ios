//
//  HomeMapLayer.swift
//  Rodi
//

import SwiftUI

struct HomeMapLayer: View {
    let shouldRenderMap: Bool
    let cameraTarget: RodiCoordinate
    let cameraRequestID: Int
    let animatedCameraRequestID: Int?
    let cameraFocus: RodiMapCameraFocus
    let userLocation: RodiCoordinate?
    let userHeadingDegrees: Double?
    let routeOverlay: RodiRouteOverlay?
    let mapMarkers: [RodiMapMarker]
    let logoBottomInset: CGFloat
    let cameraBottomInset: CGFloat
    let isInteractionEnabled: Bool
    let visibilityState: RodiMapVisibilityState
    let isAccessibilityHidden: Bool
    let onEvent: (RodiMapEvent) -> Void

    var body: some View {
        if shouldRenderMap {
            KakaoMapContainerView(
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
                visibilityState: visibilityState,
                onEvent: onEvent
            )
            .ignoresSafeArea()
            .accessibilityHidden(isAccessibilityHidden)
        } else {
            RodiColor.white.ignoresSafeArea()
        }
    }
}
