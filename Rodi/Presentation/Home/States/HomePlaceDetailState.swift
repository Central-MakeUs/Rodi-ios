//
//  HomePlaceDetailState.swift
//  Rodi
//

import Foundation

/// 선택한 장소의 서버 상세와 북마크 요청 상태를 관리한다.
struct HomePlaceDetailState {
    var selectedPlaceID: Int?
    var detail: PlaceDetail?
    var isLoading = false
    var isBookmarkUpdating = false
}
