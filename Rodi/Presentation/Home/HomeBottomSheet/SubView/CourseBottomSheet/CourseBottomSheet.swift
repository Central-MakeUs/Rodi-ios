//
//  CourseBottomSheet.swift
//  Rodi
//

import SwiftUI

/// 홈 하단의 장소 목록/선택 상세를 전환해서 보여주는 바텀싯 컨테이너.
/// Home 전체 상태를 직접 알지 않고, 바텀싯 전용 표시 상태와 액션만 입력받는다.
struct CourseBottomSheet<Drag: Gesture>: View {
    let content: CourseBottomSheetContentState
    let actions: CourseBottomSheetActions
    let visibleHeight: CGFloat
    let dragGesture: Drag
    let shouldAllowDrag: Bool
    let showsCourseDetailLocationControl: Bool
    let isCurrentLocationActive: Bool
    let currentLocationAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if content.hasSelectedItem {
                selectedDetailDragHandle
            } else {
                listDragHandle
            }

            if let selectedItem = content.selectedItem {
                SelectedCoursePanel(
                    item: selectedItem,
                    detail: content.selectedPlaceDetail,
                    isDetailLoading: content.isPlaceDetailLoading,
                    isBookmarkUpdating: content.isBookmarkUpdating,
                    isRouteLoading: content.isRouteLoading,
                    routeStatusMessage: content.routeStatusMessage,
                    userLocation: content.userLocation,
                    hasLocationPermission: content.hasLocationPermission,
                    closeAction: actions.clearSelection,
                    routeGuidanceMessageAction: actions.showRouteGuidanceMessage,
                    routeGuidancePermissionAction: actions.requestLocationPermission,
                    bookmarkAction: actions.toggleBookmark
                )
            } else if content.isFilterPresented {
                HomePracticeFilterView(
                    selection: content.filterSelection,
                    isApplying: content.isFilterApplying,
                    canApply: content.canApplyFilter,
                    resetAction: actions.resetFilter,
                    selectCategoryAction: actions.selectFilterCategory,
                    toggleTypeAction: actions.toggleFilterType,
                    selectAllAction: actions.selectAllFilterTypes,
                    applyAction: actions.applyFilter
                )
                .frame(maxWidth: .infinity)
                .frame(height: listViewportHeight, alignment: .top)
                .clipped()
            } else {
                PlaceListView(
                    items: content.placeItems,
                    isInitialLoading: content.isInitialLoading,
                    isNextPageLoading: content.isNextPageLoading,
                    errorMessage: content.listErrorMessage,
                    hasNextPage: content.hasNextPage,
                    isExpanded: content.isExpanded,
                    selectAction: actions.selectPlaceItem,
                    reloadAction: actions.reloadPlaceList,
                    loadNextPageAction: actions.loadNextPage
                )
                // 시트는 전체 높이를 가진 채 offset되므로, 목록의 스크롤 영역만
                // 실제 화면에 보이는 시트 높이로 제한한다.
                .frame(maxWidth: .infinity)
                .frame(height: listViewportHeight, alignment: .top)
                .clipped()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: content.hasSelectedItem ? nil : .infinity,
            alignment: .top
        )
        .background(RodiColor.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20 * (1 - content.pageProgress),
                topTrailingRadius: 20 * (1 - content.pageProgress)
            )
        )
        .shadow(color: RodiColor.black.opacity(0.08 * (1 - content.pageProgress)), radius: 4, x: 0, y: -3)
        .overlay(alignment: .topTrailing) {
            if showsCourseDetailLocationControl {
                CurrentLocationButton(
                    isActive: isCurrentLocationActive,
                    action: currentLocationAction
                )
                .offset(y: -(courseLocationButtonSize + courseLocationButtonSpacing))
                .padding(.trailing, 12)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAction(named: Text("펼치기")) {
            guard !content.hasSelectedItem, !content.isFilterPresented else { return }
            actions.expand()
        }
    }

    private var listViewportHeight: CGFloat {
        let dragHandleHeight: CGFloat = 10
        let listHeaderHeight: CGFloat = content.showsListHeader ? 56 : 0
        return max(0, visibleHeight - dragHandleHeight - listHeaderHeight)
    }

    private var headerTitle: String { content.isFilterPresented ? "필터" : "추천 목록" }

    private let courseLocationButtonSize: CGFloat = 40
    private let courseLocationButtonSpacing: CGFloat = 12

    private var dragIndicator: some View {
        Capsule()
            .fill(RodiColor.gray400)
            .frame(width: 60, height: 4)
            .padding(.top, 6)
            .opacity(1 - content.pageProgress)
    }

    private var selectedDetailDragHandle: some View {
        dragIndicator
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(dragGesture, including: shouldAllowDrag ? .all : .none)
    }

    private var listDragHandle: some View {
        VStack(spacing: 0) {
            dragIndicator

            if content.showsListHeader {
                CourseBottomSheetHeaderView(
                    title: headerTitle,
                    pageProgress: content.pageProgress,
                    collapseAction: actions.collapse,
                    filterAction: content.isFilterPresented ? nil : actions.presentFilter,
                    closeAction: content.isFilterPresented ? actions.closeFilter : nil
                )
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(dragGesture, including: shouldAllowDrag ? .all : .none)
    }
}
