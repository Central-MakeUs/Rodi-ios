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
    var placeDetail = HomePlaceDetailState()
    var map = HomeMapState()
    var location = HomeLocationState()
    var placeList = HomePlaceListState()
    var presentation = HomePresentationState()

    var visibleItems: [RodiCourseItem] {
        data.items
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
        // 코스 상세에서는 시작·경유·도착 경로 마커만 보여 대표 코스 마커와 겹치지 않게 한다.
        if selection.selectedItem?.type == .course,
           route.selectedRouteOverlay != nil {
            return []
        }

        if let selectedItem = selection.selectedItem {
            return selectedItem.mapMarker.map { [$0] } ?? []
        }

        return selection.visibleMapMarkers
    }
}
