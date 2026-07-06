//
//  HomeAction.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

enum HomeAction {
    case viewAction(ViewAction)
    case runtimeAction(RuntimeAction)
    case mapAction(MapAction)
    case routeAction(RouteAction)
    case presentationAction(PresentationAction)
    case delegate(Delegate)

    enum ViewAction {
        case setSheetHeight(CGFloat)
        case syncMediumSheetHeight(CGFloat)
        case syncExpandedSheetHeight(containerHeight: CGFloat, mediumHeight: CGFloat)
        case expandSheet(availableHeight: CGFloat)
        case collapseSheet(mediumHeight: CGFloat)
        case resetSheetToMedium(mediumHeight: CGFloat)
        case showAllCourses
        case applyRadiusFilter(HomeRadiusFilter)
        case radiusFilterNeedsLocationPermission
        case radiusFilterResolvingLocation
        case requestCurrentLocation
    }

    enum RuntimeAction {
        case setItems([RodiCourseItem])
        case setFilterAnchorCoordinate(RodiCoordinate)
        case setSelectedItem(RodiCourseItem?)
        case setVisibleMapMarkers([RodiMapMarker])
        case setUserLocationCoordinate(RodiCoordinate?)
        case setUserHeadingDegrees(Double?)
        case setLocationPermission(Bool)
        case setCurrentLocationButtonActive(Bool)
    }

    enum MapAction {
        case ready
        case viewportChanged(center: RodiCoordinate, zoomLevel: Int)
        case cameraMoveFinished(requestID: Int)
        case loadingFailed(String)
        case retryLoading
        case finishLoadingRetry
        case setRetryingAfterNetworkFailure(Bool)
        case setNetworkUnavailable(Bool)
        case setErrorMessage(String?)
        case setLoading(Bool)
        case setShouldRender(Bool)
        case setCameraState(
            target: RodiCoordinate,
            requestID: Int,
            animatedRequestID: Int?,
            focus: RodiMapCameraFocus
        )
        case setCameraRequestID(Int)
    }

    enum RouteAction {
        case clearSelection
        case selectItem(RodiCourseItem, mediumHeight: CGFloat)
        case selectMapMarker(markerID: String, mediumHeight: CGFloat)
        case roadRouteLoaded(courseID: Int, path: [RodiCoordinate])
        case roadRouteFailed(courseID: Int, message: String?)
        case setSelectedRouteOverlay(RodiRouteOverlay?)
        case setRouteLoading(Bool)
        case setRouteStatusMessage(String?)
    }

    enum PresentationAction {
        case showRouteGuidanceMessage(String)
        case setGuidanceSnackbarMessage(String?)
        case dismissGuidanceSnackbar
        case showLocationNoticeMessage(String)
        case setLocationNoticeMessage(String?)
        case dismissLocationNoticeMessage
        case showLocationSettingsAlert
        case setLocationSettingsAlertPresented(Bool)
        case setLegalSettingsPresented(Bool)
    }

    enum Delegate {
        case none
    }
}
