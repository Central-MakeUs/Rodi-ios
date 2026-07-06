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

        case .setFilterAnchorCoordinate(let coordinate):
            state.data.filterAnchorCoordinate = coordinate

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
        }

        return .none
    }
}
