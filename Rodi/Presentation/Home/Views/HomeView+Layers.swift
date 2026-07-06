//
//  HomeView+Layers.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

extension HomeView {
    var mapLayer: some View {
        HomeMapLayer(
            shouldRenderMap: shouldRenderMap,
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocationCoordinate,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: selectedRouteOverlay,
            mapMarkers: displayedMapMarkers,
            logoBottomInset: floatingControlBottomInset,
            cameraBottomInset: cameraObscuredBottomInset,
            isInteractionEnabled: bottomSheetState == .medium,
            visibilityState: mapVisibilityState,
            isAccessibilityHidden: bottomSheetState == .expanded,
            onEvent: handleMapEvent
        )
    }

    var statusLayer: some View {
        HomeStatusLayer(
            overlayState: overlayState,
            retryAction: retryMapLoadingFromNetworkError
        )
    }

    var radiusFilterLayer: some View {
        HomeRadiusFilterLayer(
            isVisible: shouldShowRadiusFilter,
            selectedFilter: selectedRadiusFilter,
            selectAction: handleRadiusFilterSelection
        )
    }

    var pageMorphOverlay: some View {
        RodiColor.white
            .ignoresSafeArea()
            .opacity(pageProgress)
            .allowsHitTesting(false)
            .zIndex(0.5)
    }

    var floatingControlLayer: some View {
        HomeFloatingControlLayer(
            isCurrentLocationActive: isCurrentLocationButtonActive,
            bottomInset: floatingControlBottomInset,
            opacity: locationButtonOpacity,
            allowsHitTesting: bottomSheetState == .medium && locationButtonOpacity > 0.95,
            isAccessibilityHidden: bottomSheetState == .expanded,
            spacing: Constants.floatingControlSpacing,
            legalSettingsAction: { homeStore.send(.presentationAction(.setLegalSettingsPresented(true))) },
            currentLocationAction: requestCurrentLocation
        )
    }

    var bottomSheetLayer: some View {
        HomeBottomSheetLayer(
            content: bottomSheetContentState,
            actions: bottomSheetActions,
            height: renderedSheetHeight,
            offsetY: renderedSheetOffset,
            dragGesture: sheetDragGesture,
            shouldAllowDrag: shouldAllowSheetDrag
        )
    }
}
