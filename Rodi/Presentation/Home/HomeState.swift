//
//  HomeState.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct HomeState {
    var data = HomeDataState()
    var bottomSheet = HomeBottomSheetUIState()
    var selection = HomeSelectionState()
    var route = HomeRouteState()
    var map = HomeMapState()
    var location = HomeLocationState()
    var presentation = HomePresentationState()

    var visibleItems: [RodiCourseItem] {
        guard let radius = data.selectedRadiusFilter.radiusKilometers else {
            return data.items
        }

        return data.items.filter {
            data.filterAnchorCoordinate.distanceKilometers(to: $0.coordinate) <= radius
        }
    }

    var shouldShowEmptyRadiusResult: Bool {
        data.selectedRadiusFilter != .all && visibleItems.isEmpty
    }

    var overlayState: HomeOverlayState? {
        if map.isRetryingAfterNetworkFailure {
            return .loading(.map)
        }

        if map.isNetworkUnavailable {
            return .networkUnavailable
        }

        if let mapErrorMessage = map.errorMessage {
            return .mapUnavailable(message: mapErrorMessage)
        }

        if map.isLoading {
            return .loading(.map)
        }

        return nil
    }

    var displayedMapMarkers: [RodiMapMarker] {
        if let selectedItem = selection.selectedItem {
            return selectedItem.mapMarker.map { [$0] } ?? []
        }

        return selection.visibleMapMarkers
    }
}
