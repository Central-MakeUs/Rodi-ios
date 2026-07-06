//
//  HomeView.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State var runtimeService = HomeRuntimeService()
    @StateObject var homeStore = Store(state: HomeState(), reducer: HomeReducer())
    @State var networkMonitor = HomeNetworkMonitor()
    @State var containerHeight: CGFloat = 0
    let authRepository: AuthRepository
    let onLogout: () -> Void

    init(
        authRepository: AuthRepository = AuthDependencyContainer.shared.authRepository,
        onLogout: @escaping () -> Void = {}
    ) {
        self.authRepository = authRepository
        self.onLogout = onLogout
    }

    enum Constants {
        static let sheetHeightRatio: CGFloat = 0.48
        static let floatingControlSpacing: CGFloat = 12
        static let currentLocationButtonSize: CGFloat = 40
        static let pageMorphStartRatio: CGFloat = 0.85
        static let pageSnapRatio: CGFloat = 0.9
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                statusLayer
                radiusFilterLayer
                pageMorphOverlay
                floatingControlLayer
                bottomSheetLayer
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                handleContainerHeightChange(height)
            }
            .onAppear(perform: startHomeServices)
            .onDisappear(perform: stopHomeServices)
            .animation(.easeOut(duration: 0.25), value: bottomSheetState)
        }
        .homeInteractions(
            guidanceSnackbarMessage: guidanceSnackbarMessageBinding,
            locationNoticeMessage: locationNoticeMessageBinding,
            bottomSheetState: bottomSheetState,
            mediumOverlayBottomInset: mediumOverlayBottomInset,
            showsLocationSettingsAlert: showsLocationSettingsAlertBinding,
            showsLegalSettings: showsLegalSettingsBinding,
            scenePhase: scenePhase,
            openSettingsAction: openAppSettings,
            logoutAction: performLogout,
            refreshLocationAuthorizationAction: runtimeService.refreshLocationAuthorization
        )
    }
}
