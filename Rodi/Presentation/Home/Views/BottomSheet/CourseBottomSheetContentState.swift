//
//  CourseBottomSheetContentState.swift
//  Rodi
//

import CoreGraphics

/// CourseBottomSheet가 화면을 결정하는 데 필요한 표시 상태.
/// Home은 홈 전체 상태를 소유하고, 바텀싯은 이 값만 보고 목록/빈 결과/선택 상세 중 무엇을 그릴지 결정한다.
struct CourseBottomSheetContentState {
    let items: [RodiCourseItem]
    let selectedItem: RodiCourseItem?
    let isRouteLoading: Bool
    let routeStatusMessage: String?
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let showsEmptyRadiusResult: Bool
    let pageProgress: CGFloat

    var showsListHeader: Bool {
        selectedItem == nil && !showsEmptyRadiusResult
    }

    var hasSelectedItem: Bool {
        selectedItem != nil
    }
}
