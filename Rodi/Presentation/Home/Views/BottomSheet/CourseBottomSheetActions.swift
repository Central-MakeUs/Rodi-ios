//
//  CourseBottomSheetActions.swift
//  Rodi
//

import Foundation

/// CourseBottomSheet에서 발생할 수 있는 사용자 의도를 모은 액션 묶음.
/// 뷰는 이 액션을 호출만 하고, 실제 상태 변경과 side effect는 Home MVI/Service 쪽에서 처리한다.
struct CourseBottomSheetActions {
    let selectPlaceItem: (PlaceListItem) -> Void
    let clearSelection: () -> Void
    let showRouteGuidanceMessage: (String) -> Void
    let requestLocationPermission: () -> Void
    let reloadPlaceList: () -> Void
    let loadNextPage: () -> Void
    let expand: () -> Void
    let collapse: () -> Void
}
