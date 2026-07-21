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
    @State var selectedSheetContentHeight: CGFloat = 0
    @Binding var selectedTab: RodiTab
    @Binding var pendingPlaceSelection: PlaceListItem?
    @Binding var rootBottomSheetState: HomeBottomSheetState
    @Binding var tabTapRequestID: Int
    let placeRepository: PlaceRepository
    let onAuthenticationRequired: () -> Void

    init(
        selectedTab: Binding<RodiTab> = .constant(.home),
        pendingPlaceSelection: Binding<PlaceListItem?> = .constant(nil),
        bottomSheetState: Binding<HomeBottomSheetState> = .constant(.collapsed),
        tabTapRequestID: Binding<Int> = .constant(0),
        placeRepository: PlaceRepository = AuthDependencyContainer.shared.placeRepository,
        onAuthenticationRequired: @escaping () -> Void = {}
    ) {
        _selectedTab = selectedTab
        _pendingPlaceSelection = pendingPlaceSelection
        _rootBottomSheetState = bottomSheetState
        _tabTapRequestID = tabTapRequestID
        self.placeRepository = placeRepository
        self.onAuthenticationRequired = onAuthenticationRequired
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
                bottomSheetLayer
            }
//            .onGeometryChange(for: CGFloat.self) { proxy in
//                proxy.size.height
//            } action: { height in
//                handleContainerHeightChange(height)
//            }
            .onAppear {
                startHomeServices()
                consumePendingPlaceSelectionIfNeeded()
                rootBottomSheetState = bottomSheetState
            }
            .onDisappear(perform: stopHomeServices)
            .animation(.easeOut(duration: 0.25), value: bottomSheetState)
        }
        .homeInteractions(
            guidanceSnackbarMessage: guidanceSnackbarMessageBinding,
            locationNoticeMessage: locationNoticeMessageBinding,
            bottomSheetState: bottomSheetState,
            showsLocationSettingsAlert: showsLocationSettingsAlertBinding,
            scenePhase: scenePhase,
            openSettingsAction: openAppSettings,
            refreshLocationAuthorizationAction: runtimeService.refreshLocationAuthorization
        )
        .onChange(of: homeStore.state.presentation.authenticationRequestID) { requestID in
            guard requestID > 0 else { return }
            onAuthenticationRequired()
        }
        .onChange(of: selectedItem?.id) { _ in
            selectedSheetContentHeight = 0
        }
        .onChange(of: pendingPlaceSelection) { _ in
            consumePendingPlaceSelectionIfNeeded()
        }
        .onChange(of: bottomSheetState) { state in
            rootBottomSheetState = state
        }
        .onChange(of: tabTapRequestID) { _ in
            presentBottomSheet()
        }
        .onChange(of: homeStore.state.placeList.shouldAutoExpandAfterResearch) { shouldExpand in
            guard shouldExpand else { return }
            showResearchResultsSheet()
            homeStore.send(.placeListAction(.consumeAutoExpandAfterResearch))
        }
    }
}
