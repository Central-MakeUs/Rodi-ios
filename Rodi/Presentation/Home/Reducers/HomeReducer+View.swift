//
//  HomeReducer+View.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    enum HomeEffectID {
        static let routeLoading = "home.route.loading"
        static let placeDetailLoading = "home.place-detail.loading"
        static let bookmarkUpdating = "home.place-detail.bookmark-updating"
        static let placeListLoading = "home.place-list.loading"
        static let snackbarDismissal = "home.presentation.snackbar-dismissal"
    }

    func reduceViewAction(_ action: HomeAction.ViewAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .syncMediumSheetHeight(let mediumHeight):
            if state.bottomSheet.bottomSheetState == .medium {
                state.bottomSheet.sheetHeight = mediumHeight
            }

        case .syncExpandedSheetHeight(let containerHeight, let mediumHeight):
            if state.bottomSheet.bottomSheetState == .expanded {
                state.bottomSheet.sheetHeight = max(containerHeight, mediumHeight)
            }

        case .presentSheet(let mediumHeight):
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight

        case .dismissSheet:
            state.bottomSheet.bottomSheetState = .collapsed
            state.bottomSheet.sheetHeight = 0

        case .expandSheet(let availableHeight):
            guard state.bottomSheet.bottomSheetState != .expanded else { break }
            state.bottomSheet.bottomSheetState = .expanded
            state.bottomSheet.sheetHeight = availableHeight

        case .collapseSheet(let mediumHeight):
            guard state.bottomSheet.bottomSheetState != .medium else { break }
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight

        case .resetSheetToMedium(let mediumHeight):
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight

        case .requestCurrentLocation:
            prepareCurrentLocationRequest(state: &state)
            return .cancel(id: HomeEffectID.routeLoading)

        case .requestCurrentLocationFromCourseDetail(let mediumHeight):
            // 코스 상세는 콘텐츠 높이 기반 시트라 선택만 해제하면 목록 레이아웃으로
            // 전환되는 프레임이 어긋날 수 있다. 먼저 주차장 상세와 같은 medium 목록
            // 상태를 확정한 후 현재 위치 이동을 시작한다.
            clearSelectionState(state: &state)
            state.bottomSheet.bottomSheetState = .medium
            state.bottomSheet.sheetHeight = mediumHeight
            prepareCurrentLocationRequest(state: &state)
            return .cancel(id: HomeEffectID.routeLoading)
        }

        return .none
    }

    private func prepareCurrentLocationRequest(state: inout HomeState) {
        state.selection.selectedItem = nil
        state.route.selectedRouteOverlay = nil
        state.route.routeStatusMessage = nil
        state.route.isRouteLoading = false
        state.map.cameraFocus = .currentLocation
        state.location.isCurrentLocationButtonActive = true
    }
}
