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
    var mapZoomLevel = 6
    var isCurrentLocationButtonActive = false

    var locationState: LocationState = .idle
    var locationAuthorizationState: LocationAuthorizationState = .notDetermined
    var hasCompletedInitialLocationResolution = false
    var userLocation: RodiCoordinate?
    var userHeadingDegrees: Double?
    var lastLocationResolvedAt: Date?
    var hasShownProlongedLocationUnavailableNotice = false

    var markerState: MarkerState = .idle
    var mapItems: [RodiCourseItem] = []
    var markers: [RodiMapMarker] = []
    var markerRenderingGeneration = 0
    var hasCompletedInitialMarkerRendering = false
    var displayedMarkerTier: RodiHomeMarkerClusterIndex.Tier?
    var forcedMarkerTier: RodiHomeMarkerClusterIndex.Tier?
    var forcedMarkerTierZoomLevel: Int?
    var selectedMarkerID: String?
    var selectedSearchResultName: String?
    var isResearchButtonVisible = false

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
