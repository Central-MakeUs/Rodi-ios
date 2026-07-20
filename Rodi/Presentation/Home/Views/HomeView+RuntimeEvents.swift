//
//  HomeView+RuntimeEvents.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import Foundation

extension HomeView {
    func handleRuntimeEvent(_ event: HomeRuntimeEvent) {
        switch event {
        case .selectionInvalidated:
            homeStore.send(.routeAction(.clearSelection))
        case .renderedMapMarkersChanged(let markers):
            homeStore.send(.runtimeAction(.setVisibleMapMarkers(markers)))
        case .mapErrorMessageChanged(let message):
            homeStore.send(.mapAction(.setErrorMessage(message)))
        case .mapLoadingChanged(let isLoading):
            homeStore.send(.mapAction(.setLoading(isLoading)))
        case .shouldRenderMapChanged(let shouldRender):
            homeStore.send(.mapAction(.setShouldRender(shouldRender)))
        case .cameraStateChanged(let target, let requestID, let animatedRequestID, let focus):
            homeStore.send(.mapAction(.setCameraState(
                target: target,
                requestID: requestID,
                animatedRequestID: animatedRequestID,
                focus: focus
            )))
        case .userLocationCoordinateChanged(let coordinate):
            homeStore.send(.runtimeAction(.setUserLocationCoordinate(coordinate)))
        case .userHeadingDegreesChanged(let degrees):
            homeStore.send(.runtimeAction(.setUserHeadingDegrees(degrees)))
        case .locationPermissionChanged(let hasPermission):
            homeStore.send(.runtimeAction(.setLocationPermission(hasPermission)))
        case .currentLocationButtonActiveChanged(let isActive):
            homeStore.send(.runtimeAction(.setCurrentLocationButtonActive(isActive)))
        case .initialPlaceListSearchPrepared(let origin):
            homeStore.send(.runtimeAction(.prepareInitialPlaceListSearch(origin: origin)))
        case .locationNoticeRequested(let message):
            homeStore.send(.presentationAction(.showLocationNoticeMessage(message)))
        case .locationPermissionAlertRequested:
            homeStore.send(.presentationAction(.showLocationSettingsAlert))
        }
    }
}
