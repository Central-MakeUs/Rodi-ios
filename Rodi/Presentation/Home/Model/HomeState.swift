//
//  HomeState.swift
//  Rodi
//

import Foundation

struct HomeMapState {
    var mapLifecycle: MapLifecycle = .inactive
    var isHomeTabSelected = false
    var isAppActive = true
    var isMapInteractive: Bool { isHomeTabSelected && isAppActive }

    var cameraTarget = RodiCoordinate.southKoreaCenter
    var cameraRequestID = 0
    var animatedCameraRequestID: Int?
    var cameraFocus: RodiMapCameraFocus = .koreaOverview
    var pendingRegionViewportReloadOrigin: RodiCoordinate?
    var pendingRegionCameraRequestID: Int?
    var visibleLongitudeSpan: Double?
    var isCurrentLocationButtonActive = false

    var locationState: LocationState = .idle
    var locationAuthorizationState: LocationAuthorizationState = .notDetermined
    var hasCompletedInitialLocationResolution = false
    var userLocation: RodiCoordinate?
    var userHeadingDegrees: Double?
    var lastLocationResolvedAt: Date?
    var hasShownProlongedLocationUnavailableNotice = false

    var markerState: MarkerState = .idle
    var markers: [RodiMapMarker] = []
    var markerRenderingGeneration = 0
    var hasCompletedInitialMarkerRendering = false
    var clusterQuery: PlaceClusterQuery?
    var clusterRequestRevision = 0
    var clusterListRevision = 0
    var clusterResult: PlaceClusterResult?
    var displayedClusterLevel: Int?
    var clusterBoundsByMarkerID: [String: PlaceViewport] = [:]
    var didClusterRefreshFail = false
    var selectedMarkerID: String?
    var selectedSearchResultName: String?
    var isListResearchButtonVisible = false
    var isResearchButtonVisible: Bool { isListResearchButtonVisible || didClusterRefreshFail }

    var routeOverlay: RodiRouteOverlay?
}

struct HomePresentationState {
    var pendingSnackbar: ToastStruct?
    var isLocationSettingsAlertPresented = false
    var isBottomTabBarVisible = true
    var isSearchPresented = false
    var searchOrigin: RodiCoordinate?
}

struct HomeState {
    var map = HomeMapState()
    var bottomSheet = HomeBottomSheetReducer.State()
    var search = HomeSearchReducer.State()
    var presentation = HomePresentationState()
}
