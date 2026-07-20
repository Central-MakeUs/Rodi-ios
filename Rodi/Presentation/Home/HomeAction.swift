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
    case placeListAction(PlaceListAction)
    case presentationAction(PresentationAction)
    case delegate(Delegate)

    enum ViewAction {
        case setSheetHeight(CGFloat)
        case syncMediumSheetHeight(CGFloat)
        case syncExpandedSheetHeight(containerHeight: CGFloat, mediumHeight: CGFloat)
        case presentSheet(mediumHeight: CGFloat)
        case dismissSheet
        case expandSheet(availableHeight: CGFloat)
        case collapseSheet(mediumHeight: CGFloat)
        case resetSheetToMedium(mediumHeight: CGFloat)
        case requestCurrentLocation
    }

    enum RuntimeAction {
        case setItems([RodiCourseItem])
        case setSelectedItem(RodiCourseItem?)
        case setVisibleMapMarkers([RodiMapMarker])
        case setUserLocationCoordinate(RodiCoordinate?)
        case setUserHeadingDegrees(Double?)
        case setLocationPermission(Bool)
        case setCurrentLocationButtonActive(Bool)
        case prepareInitialPlaceListSearch(origin: RodiCoordinate)
    }

    enum MapAction {
        case ready
        case viewportChanged(
            center: RodiCoordinate,
            zoomLevel: Int,
            viewport: PlaceViewport,
            isUserInitiated: Bool
        )
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
        case detailLoaded(PlaceDetail)
        case detailFailed(placeID: Int, message: String)
        case toggleBookmark
        case bookmarkUpdated(placeID: Int, isBookmarked: Bool)
        case bookmarkFailed(placeID: Int, previousDetail: PlaceDetail, message: String)
        case roadRouteLoaded(courseID: Int, path: [RodiCoordinate])
        case roadRouteFailed(courseID: Int, message: String?)
        case setSelectedRouteOverlay(RodiRouteOverlay?)
        case setRouteLoading(Bool)
        case setRouteStatusMessage(String?)
    }

    enum PlaceListAction {
        case viewportChanged(viewport: PlaceViewport, center: RodiCoordinate, isUserInitiated: Bool)
        case reloadCurrentViewport
        case loadNextPage
        case pageLoaded(
            page: PlaceCursorPage,
            viewport: PlaceViewport,
            revision: Int,
            isAppending: Bool,
            isManualResearch: Bool
        )
        case pageFailed(message: String, revision: Int, isAppending: Bool, isManualResearch: Bool)
        case consumeAutoExpandAfterResearch
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
        case requestAuthentication
    }

    enum Delegate {
        case none
    }
}
