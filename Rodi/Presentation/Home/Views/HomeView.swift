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
    @State var settlingSheetHeight: CGFloat?
    @State var selectedDetailSettlingOffset: CGFloat?
    @State var sheetSettlingID = UUID()
    @GestureState var sheetDragTranslation: CGFloat = 0
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
        static let sheetHeightRatio: CGFloat = 0.5
        static let floatingControlSpacing: CGFloat = 12
        static let currentLocationButtonSize: CGFloat = 40
        static let pageMorphStartRatio: CGFloat = 0.85
        static let expandedSheetSnapRatio: CGFloat = 0.55
        static let collapsedSheetSnapRatio: CGFloat = 0.45
        static let defaultSheetSnapDuration: TimeInterval = 0.25
        static let collapsedSheetSnapDuration: TimeInterval = 0.18
        static let selectedDetailDismissThreshold: CGFloat = 48
        static let selectedDetailDismissSnapDuration: TimeInterval = 0.18
        static let bottomTabBarHeight: CGFloat = 80
        static let bottomSheetDragCoordinateSpace = "rodi.home.bottom-sheet.drag"
    }

    var body: some View {
        NavigationStack {
            HomeStoreObservedContainer(homeStore: homeStore) {
                ZStack(alignment: .bottom) {
                    mapLayer
                    statusLayer
                    placeResearchButtonLayer
                    pageMorphOverlay
                    floatingControlLayer
                    listButtonLayer
                    bottomSheetLayer
                }
                .coordinateSpace(name: Constants.bottomSheetDragCoordinateSpace)
                .onAppear {
                    startHomeServices()
                    consumePendingPlaceSelectionIfNeeded()
                    rootBottomSheetState = bottomSheetState
                }
                .onDisappear(perform: stopHomeServices)
                .animation(.easeOut(duration: 0.25), value: bottomSheetState)
            }
        }
        .homeInteractions(
            homeStore: homeStore,
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

/// HomeView의 최상위 레이어도 Store 상태를 직접 관찰하도록 만드는 컨테이너다.
/// 지도는 별도 관찰 레이어였지만, 목록 버튼과 시트는 부모의 간접 상태 읽기에 의존해
/// 최초 마운트 시 갱신을 놓칠 수 있었다.
private struct HomeStoreObservedContainer<Content: View>: View {
    @ObservedObject var homeStore: StoreOf<HomeReducer>
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
