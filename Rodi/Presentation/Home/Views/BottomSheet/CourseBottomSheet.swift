//
//  CourseBottomSheet.swift
//  Rodi
//

import SwiftUI

/// 홈 하단의 코스 목록/빈 결과/선택 상세를 전환해서 보여주는 바텀싯 컨테이너.
/// Home 전체 상태를 직접 알지 않고, 바텀싯 전용 표시 상태와 액션만 입력받는다.
struct CourseBottomSheet: View {
    let content: CourseBottomSheetContentState
    let actions: CourseBottomSheetActions

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(RodiColor.gray400)
                .frame(width: 60, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 0)
                .opacity(1 - content.pageProgress)

            if content.showsListHeader {
                CourseBottomSheetHeaderView(
                    title: headerTitle,
                    pageProgress: content.pageProgress,
                    collapseAction: actions.collapse
                )
            }

            if let selectedItem = content.selectedItem {
                SelectedCoursePanel(
                    item: selectedItem,
                    isRouteLoading: content.isRouteLoading,
                    routeStatusMessage: content.routeStatusMessage,
                    userLocation: content.userLocation,
                    hasLocationPermission: content.hasLocationPermission,
                    closeAction: actions.clearSelection,
                    routeGuidanceMessageAction: actions.showRouteGuidanceMessage,
                    routeGuidancePermissionAction: actions.requestLocationPermission
                )
            } else if content.showsEmptyRadiusResult {
                EmptyRadiusResultView(showAllCoursesAction: actions.showAllCourses)
            } else {
                CourseListView(items: content.items, selectAction: actions.selectItem)
            }

            Spacer(minLength: 0)
        }
        .background(RodiColor.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20 * (1 - content.pageProgress),
                topTrailingRadius: 20 * (1 - content.pageProgress)
            )
        )
        .shadow(color: RodiColor.black.opacity(0.08 * (1 - content.pageProgress)), radius: 4, x: 0, y: -3)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAction(named: Text("펼치기")) {
            guard !content.hasSelectedItem, !content.showsEmptyRadiusResult else { return }
            actions.expand()
        }
    }

    private var headerTitle: String { "연습코스" }
}
