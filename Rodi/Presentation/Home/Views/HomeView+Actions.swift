//
//  HomeView+Actions.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

extension HomeView {
    func handleSheetDragEnded(predictedTranslation: CGFloat) {
        guard bottomSheetState == .medium else { return }

        if sheetLayout.shouldDismissAfterDrag(predictedTranslation: predictedTranslation) {
            dismissBottomSheet()
        } else if sheetLayout.shouldExpandAfterDrag(predictedTranslation: predictedTranslation) {
            expandBottomSheet()
        } else {
            collapseBottomSheet()
        }
    }

    func expandBottomSheet() {
        guard bottomSheetState != .expanded else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            homeStore.send(.viewAction(.expandSheet(availableHeight: availableSheetHeight)))
        }
    }

    func collapseBottomSheet() {
        guard bottomSheetState != .collapsed else { return }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.collapseSheet(mediumHeight: mediumSheetHeight)))
        }
    }

    func presentBottomSheet() {
        guard bottomSheetState == .collapsed else { return }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.presentSheet(mediumHeight: mediumSheetHeight)))
        }
    }

    func dismissBottomSheet() {
        guard bottomSheetState == .medium, !hasFixedBottomSheet else { return }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            homeStore.send(.viewAction(.dismissSheet))
        }
    }

    func clearSelectedCourse() {
        withAnimation(.easeOut(duration: 0.2)) {
            homeStore.send(.routeAction(.clearSelection))
        }
    }

    func handleCourseSelection(_ item: RodiCourseItem) {
        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.routeAction(.selectItem(item, mediumHeight: mediumSheetHeight)))
        }
    }

    func handleMapMarkerTap(_ markerID: String) {
        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.routeAction(.selectMapMarker(markerID: markerID, mediumHeight: mediumSheetHeight)))
        }
    }

    func handleRadiusFilterSelection(_ filter: HomeRadiusFilter) {
        guard filter != .all else {
            homeStore.send(.viewAction(.applyRadiusFilter(filter)))
            runtimeService.restartProgressiveMarkerRendering(for: homeStore.state.visibleItems)
            return
        }

        guard hasLocationPermission else {
            homeStore.send(.viewAction(.radiusFilterNeedsLocationPermission))
            return
        }

        guard userLocationCoordinate != nil else {
            homeStore.send(.viewAction(.radiusFilterResolvingLocation))
            runtimeService.requestLocation(kind: .userInitiated)
            return
        }

        homeStore.send(.viewAction(.applyRadiusFilter(filter)))
        runtimeService.restartProgressiveMarkerRendering(for: homeStore.state.visibleItems)
    }

    func showAllCourses() {
        homeStore.send(.viewAction(.applyRadiusFilter(.all)))
        runtimeService.restartProgressiveMarkerRendering(for: homeStore.state.visibleItems)
    }

    func openAppSettings() {
        openSystemAppSettings()
    }

    func openSystemAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        UIApplication.shared.open(url, options: [:]) { didOpen in
            RodiLogger.info("Open system app settings requested url=\(url.absoluteString), didOpen=\(didOpen)")
        }
    }

    func showRouteGuidanceMessage(_ message: String) {
        homeStore.send(.presentationAction(.showRouteGuidanceMessage(message)))
    }

    func showLocationSettingsAlert() {
        homeStore.send(.presentationAction(.showLocationSettingsAlert))
    }

    func requestCurrentLocation() {
        RodiLogger.info(
            "Current location floating button tapped selectedItem=\(selectedItem?.id.description ?? "nil"), userLocation=\(userLocationCoordinate.logDescription), cameraTarget=\(RodiLogger.coordinate(cameraTarget)), cameraRequestID=\(cameraRequestID)"
        )
        homeStore.send(.viewAction(.requestCurrentLocation))
        runtimeService.requestCurrentLocationAfterStoreUpdate(
            minimumCameraRequestID: homeStore.state.map.cameraRequestID,
            visibleItems: homeStore.state.visibleItems
        )
    }
}
