//
//  CourseDetailBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct CourseDetailBottomSheetView: View {
    let state: CourseDetailBottomSheetReducer.State
    let send: (CourseDetailBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let requestLocationPermission: () -> Void

    @State private var isGuidanceDialogPresented = false

    var body: some View {
        if let detail = state.detail {
            sheet(detail: detail)
        }
    }
}


// MARK: - Layout
extension CourseDetailBottomSheetView {

    private func sheet(detail: PlaceDetail) -> some View {
        VStack(spacing: 0) {
            CourseSelectedDetailPanel(
                detail: detail,
                isBookmarkUpdating: state.isBookmarkUpdating,
                isRouteLoading: state.isRouteLoading,
                isRouteGuidanceEnabled: detail.course?.waypoints.count ?? 0 >= 2,
                closeAction: { send(.dismiss) },
                bookmarkAction: { send(.toggleBookmark) },
                routeGuidanceAction: requestRouteGuidance
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .confirmationDialog("경로 안내 앱 선택", isPresented: $isGuidanceDialogPresented, titleVisibility: .visible) {
            Button("카카오맵으로 보기") { openRouteGuidance(.kakaoMap, detail: detail) }
            Button("카카오내비로 안내") { openRouteGuidance(.kakaoNavi, detail: detail) }
            Button("취소", role: .cancel) {}
        } message: {
            Text("출발지, 경유지, 도착지를 함께 전달해요.")
        }
    }

    private func requestRouteGuidance() {
        guard hasLocationPermission else {
            requestLocationPermission()
            return
        }
        guard userLocation != nil else {
            send(.delegate(.showSnackbar("현재 위치를 확인한 뒤 다시 시도해주세요.")))
            return
        }
        isGuidanceDialogPresented = true
    }

    private func openRouteGuidance(_ app: RouteGuidanceApp, detail: PlaceDetail) {
        Task {
            let result = await RouteGuidanceService.shared.open(app, for: RodiCourseItem(placeDetail: detail), userLocation: userLocation)
            if let message = result.userMessage { send(.delegate(.showSnackbar(message))) }
        }
    }
}
