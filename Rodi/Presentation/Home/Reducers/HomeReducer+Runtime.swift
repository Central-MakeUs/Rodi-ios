//
//  HomeReducer+Runtime.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reduceRuntimeAction(_ action: HomeAction.RuntimeAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .setItems(let items):
            state.data.items = items

        case .setSelectedItem(let item):
            state.selection.selectedItem = item

        case .setVisibleMapMarkers(let markers):
            state.selection.visibleMapMarkers = markers

        case .setUserLocationCoordinate(let coordinate):
            state.location.userLocationCoordinate = coordinate

        case .setUserHeadingDegrees(let degrees):
            state.location.userHeadingDegrees = degrees

        case .setLocationPermission(let hasPermission):
            state.location.hasLocationPermission = hasPermission

        case .setCurrentLocationButtonActive(let isActive):
            state.location.isCurrentLocationButtonActive = isActive

        case .prepareInitialPlaceListSearch(let origin):
            guard state.placeList.activeViewport == nil else { break }
            state.placeList.pendingInitialSearchOrigin = origin

            if let viewport = state.placeList.latestViewport,
               let center = state.placeList.latestViewportCenter,
               center.distanceKilometers(to: origin) <= 0.5 {
                return .run { send in
                    await send(.placeListAction(.viewportChanged(
                        viewport: viewport,
                        center: center,
                        isUserInitiated: false
                    )))
                }
            }
        }

        return .none
    }
}
