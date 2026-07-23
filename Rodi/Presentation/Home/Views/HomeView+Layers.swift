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
            homeStore: homeStore,
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
            homeStore: homeStore,
            retryAction: retryMapLoadingFromNetworkError
        )
    }

    var placeResearchButtonLayer: some View {
        Group {
            if shouldShowPlaceResearchButton {
                VStack {
                    HomeResearchButton(
                        isLoading: placeListState.isManualResearchLoading,
                        action: reloadPlaceList
                    )
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
        Group {
            if !usesContentSizedSelectedDetail,
               bottomSheetState != .expanded || hasFixedBottomSheet {
                HomeFloatingControlLayer(
                    isCurrentLocationActive: isCurrentLocationButtonActive,
                    mapZoomLevel: mapZoomLevel,
                    bottomInset: floatingControlBottomInset,
                    opacity: locationButtonOpacity,
                    allowsHitTesting: locationButtonOpacity > 0.95,
                    isAccessibilityHidden: false,
                    spacing: Constants.floatingControlSpacing,
                    currentLocationAction: requestCurrentLocation
                )
            }
        }
    }

    var bottomSheetLayer: some View {
        HomeBottomSheetLayer(
            content: bottomSheetContentState,
            actions: bottomSheetActions,
            height: renderedSheetHeight,
            visibleHeight: visibleSheetHeight,
            usesIntrinsicHeight: usesContentSizedSelectedDetail,
            offsetY: renderedSheetOffset,
            opacity: bottomSheetOpacity,
            dragGesture: sheetDragGesture,
            shouldAllowDrag: shouldAllowSheetDrag,
            showsCourseDetailLocationControl: usesContentSizedSelectedDetail,
            isCurrentLocationActive: isCurrentLocationButtonActive,
            currentLocationAction: requestCurrentLocationFromCourseDetail,
            contentHeightAction: { height in
                guard abs(selectedSheetContentHeight - height) > 0.5 else { return }
                selectedSheetContentHeight = height
            }
        )
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
