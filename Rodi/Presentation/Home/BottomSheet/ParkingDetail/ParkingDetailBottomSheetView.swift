//
//  ParkingDetailBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct ParkingDetailBottomSheetView: View {
    let state: ParkingDetailBottomSheetReducer.State
    let send: (ParkingDetailBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let requestLocationPermission: () -> Void
    @State private var isGuidanceDialogPresented = false

    var body: some View {
        if let detail = state.detail {
            ParkingSelectedDetailPanel(
                detail: detail,
                isBookmarkUpdating: state.isBookmarkUpdating,
                isRouteLoading: false,
                isRouteGuidanceEnabled: true,
                closeAction: { send(.dismiss) },
                bookmarkAction: { send(.toggleBookmark) },
                routeGuidanceAction: requestRouteGuidance
            )
            .frame(maxWidth: .infinity, alignment: .top)
            .confirmationDialog("경로 안내 앱 선택", isPresented: $isGuidanceDialogPresented, titleVisibility: .visible) {
                Button("카카오맵으로 보기") { openRouteGuidance(.kakaoMap, detail: detail) }
                Button("카카오내비로 안내") { openRouteGuidance(.kakaoNavi, detail: detail) }
                Button("취소", role: .cancel) {}
            } message: {
                Text("현재 위치에서 선택한 장소까지 안내해요.")
            }
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
