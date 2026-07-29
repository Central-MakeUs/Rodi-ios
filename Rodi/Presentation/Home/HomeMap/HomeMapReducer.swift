//
//  HomeMapReducer.swift
//  Rodi
//

import Foundation

struct HomeMapReducer: Reducer {
    struct State {
        var items: [RodiCourseItem] = []
        var visibleMapMarkers: [RodiMapMarker] = []

        var isRetryingAfterNetworkFailure = false
        var isNetworkUnavailable = false
        var errorMessage: String?
        var isLoading = true
        var isReady = false
        var shouldRender = false
        var cameraTarget = RodiCoordinate.seoulCityHall
        var zoomLevel = RodiMapViewport.initial.zoomLevel
        var cameraRequestID = 0
        var animatedCameraRequestID: Int?
        var cameraFocus: RodiMapCameraFocus = .normal
        var currentLocationRequestID = 0

        var userLocationCoordinate: RodiCoordinate?
        var userHeadingDegrees: Double?
        var hasLocationPermission = false
        var isCurrentLocationButtonActive = false
    }

    enum Action {
        case ready
        case viewportChanged(center: RodiCoordinate, zoomLevel: Int, viewport: PlaceViewport, isUserInitiated: Bool)
        case cameraMoveFinished(requestID: Int)
        case loadingFailed(String)
        case retryLoading
        case finishLoadingRetry
        case setRetryingAfterNetworkFailure(Bool)
        case setNetworkUnavailable(Bool)
        case setErrorMessage(String?)
        case setLoading(Bool)
        case setShouldRender(Bool)
        case setCameraState(target: RodiCoordinate, requestID: Int, animatedRequestID: Int?, focus: RodiMapCameraFocus)
        case setItems([RodiCourseItem])
        case setVisibleMapMarkers([RodiMapMarker])
        case setUserLocationCoordinate(RodiCoordinate?)
        case setUserHeadingDegrees(Double?)
        case setLocationPermission(Bool)
        case setCurrentLocationButtonActive(Bool)
        case requestCurrentLocation
        case focusParking(RodiCoordinate)
        case focusAdministrativeArea(RodiCoordinate, bounds: RodiMapBounds)
        case delegate(Delegate)
    }

    enum Delegate {
        case prepareInitialPlaceListSearch(origin: RodiCoordinate)
    }

    func reduce(
        _ state: inout State,
        with action: Action
    ) -> Effect<Action> {
        switch action {
        case .ready:
            state.errorMessage = nil
            state.isReady = true
            state.isLoading = false

        case .viewportChanged(_, let zoomLevel, _, _):
            state.zoomLevel = zoomLevel

        case .cameraMoveFinished(let requestID):
            guard state.animatedCameraRequestID == requestID else { break }
            state.animatedCameraRequestID = nil
            state.isCurrentLocationButtonActive = false

        case .loadingFailed(let message):
            state.errorMessage = message
            state.isReady = false
            state.isLoading = false

        case .retryLoading:
            guard state.isNetworkUnavailable else { break }
            state.isRetryingAfterNetworkFailure = true
            state.isLoading = true
            return .run { send in
                try? await Task.sleep(for: .milliseconds(1200))
                await send(.finishLoadingRetry)
            }

        case .finishLoadingRetry:
            state.isRetryingAfterNetworkFailure = false
            state.isLoading = !state.isReady

        case .setRetryingAfterNetworkFailure(let isRetrying):
            state.isRetryingAfterNetworkFailure = isRetrying

        case .setNetworkUnavailable(let isUnavailable):
            state.isNetworkUnavailable = isUnavailable

        case .setErrorMessage(let message):
            state.errorMessage = message

        case .setLoading(let isLoading):
            state.isLoading = isLoading

        case .setShouldRender(let shouldRender):
            state.shouldRender = shouldRender

        case .setCameraState(let target, let requestID, let animatedRequestID, let focus):
            state.cameraTarget = target
            state.cameraRequestID = requestID
            state.animatedCameraRequestID = animatedRequestID
            state.cameraFocus = focus

        case .setItems(let items):
            state.items = items

        case .setVisibleMapMarkers(let markers):
            state.visibleMapMarkers = markers

        case .setUserLocationCoordinate(let coordinate):
            state.userLocationCoordinate = coordinate

        case .setUserHeadingDegrees(let degrees):
            state.userHeadingDegrees = degrees

        case .setLocationPermission(let hasPermission):
            state.hasLocationPermission = hasPermission

        case .setCurrentLocationButtonActive(let isActive):
            state.isCurrentLocationButtonActive = isActive

        case .requestCurrentLocation:
            state.cameraFocus = .currentLocation
            state.isCurrentLocationButtonActive = true
            state.currentLocationRequestID += 1
            return .cancel(id: HomeEffectID.routeLoading)

        case .focusParking(let coordinate):
            state.cameraTarget = coordinate
            state.cameraFocus = .closeSingleLocation
            state.cameraRequestID += 1
            state.animatedCameraRequestID = state.cameraRequestID

        case .focusAdministrativeArea(let coordinate, let bounds):
            state.cameraTarget = coordinate
            state.cameraFocus = .administrativeArea(bounds)
            state.cameraRequestID += 1
            state.animatedCameraRequestID = state.cameraRequestID

        case .delegate:
            break
        }

        return .none
    }
}
