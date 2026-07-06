//
//  HomeView+State.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension HomeView {
    var bottomSheetState: HomeBottomSheetState {
        homeStore.state.bottomSheet.bottomSheetState
    }

    var selectedRadiusFilter: HomeRadiusFilter {
        homeStore.state.data.selectedRadiusFilter
    }

    var selectedItem: RodiCourseItem? {
        homeStore.state.selection.selectedItem
    }

    var selectedRouteOverlay: RodiRouteOverlay? {
        homeStore.state.route.selectedRouteOverlay
    }

    var displayedMapMarkers: [RodiMapMarker] {
        homeStore.state.displayedMapMarkers
    }

    var isRouteLoading: Bool {
        homeStore.state.route.isRouteLoading
    }

    var routeStatusMessage: String? {
        homeStore.state.route.routeStatusMessage
    }

    var overlayState: HomeOverlayState? {
        homeStore.state.overlayState
    }

    var shouldRenderMap: Bool {
        homeStore.state.map.shouldRender
    }

    var cameraTarget: RodiCoordinate {
        homeStore.state.map.cameraTarget
    }

    var cameraRequestID: Int {
        homeStore.state.map.cameraRequestID
    }

    var animatedCameraRequestID: Int? {
        homeStore.state.map.animatedCameraRequestID
    }

    var cameraFocus: RodiMapCameraFocus {
        homeStore.state.map.cameraFocus
    }

    var userLocationCoordinate: RodiCoordinate? {
        homeStore.state.location.userLocationCoordinate
    }

    var userHeadingDegrees: Double? {
        homeStore.state.location.userHeadingDegrees
    }

    var hasLocationPermission: Bool {
        homeStore.state.location.hasLocationPermission
    }

    var isCurrentLocationButtonActive: Bool {
        homeStore.state.location.isCurrentLocationButtonActive
    }

    var visibleItems: [RodiCourseItem] {
        homeStore.state.visibleItems
    }

    var shouldShowEmptyRadiusResult: Bool {
        homeStore.state.shouldShowEmptyRadiusResult
    }
}
