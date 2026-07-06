//
//  HomeSelectionState.swift
//  Rodi
//

import Foundation

/// 사용자가 선택한 코스/주차장과 지도에 현재 노출 중인 마커를 관리한다.
struct HomeSelectionState {
    var selectedItem: RodiCourseItem?
    var visibleMapMarkers: [RodiMapMarker] = []
}
