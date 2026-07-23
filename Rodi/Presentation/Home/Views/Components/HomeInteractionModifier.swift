//
//  HomeInteractionModifier.swift
//  Rodi
//

import SwiftUI

struct HomeInteractionModifier: ViewModifier {
    @ObservedObject var homeStore: StoreOf<HomeReducer>
    let scenePhase: ScenePhase
    let openSettingsAction: () -> Void
    let refreshLocationAuthorizationAction: () -> Void

    func body(content: Content) -> some View {
        content
            .rodiSnackbar(message: homeStore.state.presentation.snackbarMessage)
            .alert("위치 접근 권한이 필요해요", isPresented: locationSettingsAlertBinding) {
                Button("취소", role: .cancel) {}
                Button("확인", action: openSettingsAction)
            } message: {
                Text("현 위치 기반 기능을 사용하려면 설정에서 위치 접근을 '앱을 사용하는 동안 허용'으로 변경해주세요.")
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                refreshLocationAuthorizationAction()
            }
    }

    private var locationSettingsAlertBinding: Binding<Bool> {
        Binding(
            get: { homeStore.state.presentation.showsLocationSettingsAlert },
            set: { homeStore.send(.presentationAction(.setLocationSettingsAlertPresented($0))) }
        )
    }

}

extension View {
    func homeInteractions(
        homeStore: StoreOf<HomeReducer>,
        scenePhase: ScenePhase,
        openSettingsAction: @escaping () -> Void,
        refreshLocationAuthorizationAction: @escaping () -> Void
    ) -> some View {
        modifier(
            HomeInteractionModifier(
                homeStore: homeStore,
                scenePhase: scenePhase,
                openSettingsAction: openSettingsAction,
                refreshLocationAuthorizationAction: refreshLocationAuthorizationAction
            )
        )
    }
}
