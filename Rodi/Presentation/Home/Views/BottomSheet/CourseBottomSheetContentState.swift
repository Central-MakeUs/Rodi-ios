//
//  CourseBottomSheetContentState.swift
//  Rodi
//

import CoreGraphics

/// CourseBottomSheet가 화면을 결정하는 데 필요한 표시 상태.
/// Home은 홈 전체 상태를 소유하고, 바텀싯은 이 값만 보고 목록/빈 결과/선택 상세 중 무엇을 그릴지 결정한다.
struct CourseBottomSheetContentState {
    let placeItems: [PlaceListItem]
    let selectedItem: RodiCourseItem?
    let selectedPlaceDetail: PlaceDetail?
    let isPlaceDetailLoading: Bool
    let isBookmarkUpdating: Bool
    let isRouteLoading: Bool
    let routeStatusMessage: String?
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let isInitialLoading: Bool
    let isNextPageLoading: Bool
    let listErrorMessage: String?
    let hasNextPage: Bool
    let pageProgress: CGFloat
    let isExpanded: Bool

    var showsListHeader: Bool {
        // 기본 시트는 피그마의 안내 상태처럼 핸들만 보이고,
        // 전체 화면으로 확장했을 때만 목록 앱바를 노출한다.
        selectedItem == nil && (!placeItems.isEmpty || isExpanded)
    }

    var hasSelectedItem: Bool {
        selectedItem != nil
    }
}
