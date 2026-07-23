//
//  HomeMapLayer.swift
//  Rodi
//

import SwiftUI

struct HomeMapLayer: View {
    @ObservedObject var homeStore: StoreOf<HomeReducer>
    let logoBottomInset: CGFloat
    let cameraBottomInset: CGFloat
    let isInteractionEnabled: Bool
    let visibilityState: RodiMapVisibilityState
    let isAccessibilityHidden: Bool
    let onEvent: (RodiMapEvent) -> Void

    var body: some View {
        // 첫 렌더의 조건부 생성은 SwiftUI 업데이트 타이밍에 따라 지도 UIView가 마운트되지
        // 않는 경우가 있다. 지도 엔진은 홈이 보이는 동안 유지하고 로딩 상태만 별도로 제어한다.
        KakaoMapContainerView(
            cameraTarget: homeStore.state.map.cameraTarget,
            cameraRequestID: homeStore.state.map.cameraRequestID,
            animatedCameraRequestID: homeStore.state.map.animatedCameraRequestID,
            cameraFocus: homeStore.state.map.cameraFocus,
            userLocation: homeStore.state.location.userLocationCoordinate,
            userHeadingDegrees: homeStore.state.location.userHeadingDegrees,
            routeOverlay: homeStore.state.route.selectedRouteOverlay,
            mapMarkers: homeStore.state.displayedMapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState,
            onEvent: onEvent
        )
        .ignoresSafeArea()
        .accessibilityHidden(isAccessibilityHidden)
    }
}
