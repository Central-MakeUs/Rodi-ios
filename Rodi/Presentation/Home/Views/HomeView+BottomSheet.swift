//
//  HomeView+BottomSheet.swift
//  Rodi
//

import Foundation

extension HomeView {
    var bottomSheetContentState: CourseBottomSheetContentState {
        CourseBottomSheetContentState(
            items: visibleItems,
            selectedItem: selectedItem,
            isRouteLoading: isRouteLoading,
            routeStatusMessage: routeStatusMessage,
            userLocation: userLocationCoordinate,
            hasLocationPermission: hasLocationPermission,
            showsEmptyRadiusResult: shouldShowEmptyRadiusResult,
            pageProgress: hasFixedBottomSheet ? 0 : pageProgress
        )
    }

    var bottomSheetActions: CourseBottomSheetActions {
        CourseBottomSheetActions(
            selectItem: handleCourseSelection,
            clearSelection: clearSelectedCourse,
            showRouteGuidanceMessage: showRouteGuidanceMessage,
            requestLocationPermission: showLocationSettingsAlert,
            showAllCourses: showAllCourses,
            expand: expandBottomSheet,
            collapse: collapseBottomSheet
        )
    }
}
