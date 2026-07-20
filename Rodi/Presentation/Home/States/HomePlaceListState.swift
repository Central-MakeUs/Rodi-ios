//
//  HomePlaceListState.swift
//  Rodi
//

import Foundation

/// 현재 지도 뷰포트에 대응하는 바텀싯 목록의 페이징과 재검색 상태를 관리한다.
struct HomePlaceListState {
    var items: [PlaceListItem] = []
    var activeViewport: PlaceViewport?
    var latestViewport: PlaceViewport?
    var latestViewportCenter: RodiCoordinate?
    var pendingInitialSearchOrigin: RodiCoordinate?
    var requestOrigin: RodiCoordinate?
    var nextCursor: String?
    var hasNext = false
    var totalCount: Int?
    var isInitialLoading = false
    var isNextPageLoading = false
    var errorMessage: String?
    var needsResearch = false
    var requestRevision = 0
}
