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
            isInteractionEnabled: bottomSheetState != .expanded,
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

    var placeResearchButtonLayer: some View {
        Group {
            if shouldShowPlaceResearchButton {
                VStack {
                    HomeResearchButton(action: reloadPlaceList)
                        .padding(.top, 64)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(0.7)
            }
        }
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
            mapZoomLevel: mapZoomLevel,
            bottomInset: floatingControlBottomInset,
            opacity: locationButtonOpacity,
            allowsHitTesting: bottomSheetState != .expanded && locationButtonOpacity > 0.95,
            isAccessibilityHidden: bottomSheetState == .expanded,
            spacing: Constants.floatingControlSpacing,
            currentLocationAction: requestCurrentLocation
        )
    }

    var bottomSheetLayer: some View {
        HomeBottomSheetLayer(
            content: bottomSheetContentState,
            actions: bottomSheetActions,
            height: renderedSheetHeight,
            offsetY: renderedSheetOffset,
            opacity: bottomSheetOpacity,
            dragGesture: sheetDragGesture,
            shouldAllowDrag: shouldAllowSheetDrag
        )
    }

    var bottomTabBarLayer: some View {
        Group {
            if bottomSheetState != .expanded, !hasSelectedBottomSheet {
                RodiBottomTabBar(
                    selectedTab: selectedTab,
                    homeAction: presentBottomSheet,
                    myAction: { selectedTab = .my }
                )
                .opacity(bottomTabBarOpacity)
                .offset(y: bottomTabBarOffset)
                .animation(.easeOut(duration: 0.18), value: bottomSheetState)
                .allowsHitTesting(bottomTabBarOpacity > 0.95)
                .zIndex(0.8)
            }
        }
    }

    var listButtonLayer: some View {
        Group {
            if bottomSheetState != .expanded, !hasSelectedBottomSheet, shouldRenderMap {
                VStack {
                    Spacer()

                    HomeListButton(action: presentBottomSheet)
                        .padding(.bottom, Constants.bottomTabBarHeight + 16)
                        .opacity(bottomTabBarOpacity)
                        .offset(y: bottomTabBarOffset)
                        .animation(.easeOut(duration: 0.18), value: bottomSheetState)
                        .allowsHitTesting(bottomTabBarOpacity > 0.95)
                }
                .transition(.opacity)
                .zIndex(0.8)
            }
        }
    }
}
