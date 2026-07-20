//
//  HomeView+BottomSheet.swift
//  Rodi
//

import Foundation

extension HomeView {
    var bottomSheetContentState: CourseBottomSheetContentState {
        CourseBottomSheetContentState(
            placeItems: placeListState.items,
            selectedItem: selectedItem,
            isRouteLoading: isRouteLoading,
            routeStatusMessage: routeStatusMessage,
            userLocation: userLocationCoordinate,
            hasLocationPermission: hasLocationPermission,
            isInitialLoading: placeListState.isInitialLoading,
            isNextPageLoading: placeListState.isNextPageLoading,
            listErrorMessage: placeListState.errorMessage,
            hasNextPage: placeListState.hasNext,
            pageProgress: hasFixedBottomSheet ? 0 : pageProgress
        )
    }

    var bottomSheetActions: CourseBottomSheetActions {
        CourseBottomSheetActions(
            selectPlaceItem: handlePlaceListSelection,
            clearSelection: clearSelectedCourse,
            showRouteGuidanceMessage: showRouteGuidanceMessage,
            requestLocationPermission: showLocationSettingsAlert,
            reloadPlaceList: reloadPlaceList,
            loadNextPage: loadNextPlaceListPage,
            expand: expandBottomSheet,
            collapse: collapseBottomSheet
        )
    }
}
