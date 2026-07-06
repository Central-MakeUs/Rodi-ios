//
//  HomeInteractionModifier.swift
//  Rodi
//

import SwiftUI

struct HomeInteractionModifier: ViewModifier {
    @Binding var guidanceSnackbarMessage: String?
    @Binding var locationNoticeMessage: String?
    let bottomSheetState: HomeBottomSheetState
    let mediumOverlayBottomInset: CGFloat
    @Binding var showsLocationSettingsAlert: Bool
    @Binding var showsLegalSettings: Bool
    let scenePhase: ScenePhase
    let openSettingsAction: () -> Void
    let logoutAction: () -> Void
    let refreshLocationAuthorizationAction: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                guidanceSnackbar
            }
            .overlay(alignment: .top) {
                locationNoticeSnackbar
            }
            .animation(.easeInOut(duration: 0.2), value: locationNoticeMessage)
            .animation(.easeInOut(duration: 0.2), value: guidanceSnackbarMessage)
            .alert("위치 접근 권한이 필요해요", isPresented: $showsLocationSettingsAlert) {
                Button("취소", role: .cancel) {}
                Button("확인", action: openSettingsAction)
            } message: {
                Text("현 위치 기반 기능을 사용하려면 설정에서 위치 접근을 '앱을 사용하는 동안 허용'으로 변경해주세요.")
            }
            .sheet(isPresented: $showsLegalSettings) {
                LegalSettingsView(logoutAction: logoutAction)
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                refreshLocationAuthorizationAction()
            }
    }

    @ViewBuilder
    private var guidanceSnackbar: some View {
        if let guidanceSnackbarMessage {
            SnackbarView(message: guidanceSnackbarMessage)
                .padding(.horizontal, 16)
                .padding(.bottom, mediumOverlayBottomInset)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var locationNoticeSnackbar: some View {
        if let locationNoticeMessage, bottomSheetState == .medium {
            SnackbarView(message: locationNoticeMessage)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

}

extension View {
    func homeInteractions(
        guidanceSnackbarMessage: Binding<String?>,
        locationNoticeMessage: Binding<String?>,
        bottomSheetState: HomeBottomSheetState,
        mediumOverlayBottomInset: CGFloat,
        showsLocationSettingsAlert: Binding<Bool>,
        showsLegalSettings: Binding<Bool>,
        scenePhase: ScenePhase,
        openSettingsAction: @escaping () -> Void,
        logoutAction: @escaping () -> Void,
        refreshLocationAuthorizationAction: @escaping () -> Void
    ) -> some View {
        modifier(
            HomeInteractionModifier(
                guidanceSnackbarMessage: guidanceSnackbarMessage,
                locationNoticeMessage: locationNoticeMessage,
                bottomSheetState: bottomSheetState,
                mediumOverlayBottomInset: mediumOverlayBottomInset,
                showsLocationSettingsAlert: showsLocationSettingsAlert,
                showsLegalSettings: showsLegalSettings,
                scenePhase: scenePhase,
                openSettingsAction: openSettingsAction,
                logoutAction: logoutAction,
                refreshLocationAuthorizationAction: refreshLocationAuthorizationAction
            )
        )
    }
}
