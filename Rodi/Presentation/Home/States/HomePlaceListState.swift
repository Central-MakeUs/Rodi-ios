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
    /// 재검색 버튼으로 시작된 요청은 카메라 기준이 바뀌면 안전하게 취소한다.
    var isManualResearchLoading = false
    /// 재검색 성공 후 목록 시트를 한 번만 확장하도록 View에 전달한다.
    var shouldAutoExpandAfterResearch = false
    var errorMessage: String?
    var needsResearch = false
    var requestRevision = 0
}
