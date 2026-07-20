//
//  HomeView.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var runtimeService = HomeRuntimeService()
    @StateObject var homeStore: StoreOf<HomeReducer>
    @State var networkMonitor = HomeNetworkMonitor()
    @State var containerHeight: CGFloat = 0
    @Binding var selectedTab: RodiTab
    let placeRepository: PlaceRepository

    init(
        selectedTab: Binding<RodiTab> = .constant(.home),
        placeRepository: PlaceRepository = AuthDependencyContainer.shared.placeRepository
    ) {
        _selectedTab = selectedTab
        self.placeRepository = placeRepository
        _homeStore = StateObject(
            wrappedValue: Store(
                state: HomeState(),
                reducer: HomeReducer(placeRepository: placeRepository)
            )
        )
    }

    enum Constants {
        static let sheetHeightRatio: CGFloat = 0.48
        static let floatingControlSpacing: CGFloat = 12
        static let currentLocationButtonSize: CGFloat = 40
        static let pageMorphStartRatio: CGFloat = 0.85
        static let pageSnapRatio: CGFloat = 0.9
        static let bottomTabBarHeight: CGFloat = 80
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                statusLayer
                placeResearchButtonLayer
                pageMorphOverlay
                floatingControlLayer
                listButtonLayer
                bottomTabBarLayer
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
            scenePhase: scenePhase,
            openSettingsAction: openAppSettings,
            refreshLocationAuthorizationAction: runtimeService.refreshLocationAuthorization
        )
    }
}
