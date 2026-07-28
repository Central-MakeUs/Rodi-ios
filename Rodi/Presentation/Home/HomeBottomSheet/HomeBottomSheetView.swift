//
//  HomeBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct HomeBottomSheetView: View {
    private enum Constants {
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
        static let dragCoordinateSpace = "rodi.home.bottom-sheet.drag"
    }

    @ObservedObject private var homeStore: StoreOf<HomeReducer>
    @ObservedObject private var router: HomeRouter
    private let isHomeTabSelected: () -> Bool
    private let placeRepository: PlaceRepository

    @State private var selectedSheetContentHeight: CGFloat = 0
    @State private var settlingSheetHeight: CGFloat?
    @State private var selectedDetailSettlingOffset: CGFloat?
    @State private var sheetSettlingID = UUID()
    @GestureState private var sheetDragTranslation: CGFloat = 0

    init(
        homeStore: StoreOf<HomeReducer>,
        router: HomeRouter,
        isHomeTabSelected: @escaping () -> Bool,
        placeRepository: PlaceRepository
    ) {
        self.homeStore = homeStore
        self.router = router
        self.isHomeTabSelected = isHomeTabSelected
        self.placeRepository = placeRepository
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeMapView(
                homeStore: homeStore,
                placeRepository: placeRepository,
                configuration: .init(
                    logoBottomInset: floatingControlBottomInset,
                    cameraBottomInset: cameraObscuredBottomInset,
                    isInteractionEnabled: bottomSheetState != .expanded,
                    visibilityState: mapVisibilityState,
                    isAccessibilityHidden: bottomSheetState == .expanded,
                    showsFloatingControl: !usesContentSizedSelectedDetail &&
                        (bottomSheetState != .expanded || hasFixedBottomSheet),
                    floatingControlOpacity: locationButtonOpacity,
                    allowsFloatingControlHitTesting: locationButtonOpacity > 0.95,
                    showsResearchButton: shouldShowPlaceResearchButton,
                    isResearchLoading: placeList.isManualResearchLoading
                ),
                onOutput: handleMapOutput
            )

            pageMorphOverlay
            listButtonLayer
            bottomSheetLayer
        }
        .coordinateSpace(name: Constants.dragCoordinateSpace)
        .onAppear {
            consumePendingPlaceSelectionIfNeeded()
            router.updateBottomSheetState(bottomSheetState)
        }
        .animation(.easeOut(duration: 0.25), value: bottomSheetState)
        .onChange(of: selectedItem?.id) { _ in
            selectedSheetContentHeight = 0
        }
        .onChange(of: router.pendingPlaceID) { _ in
            consumePendingPlaceSelectionIfNeeded()
        }
        .onChange(of: bottomSheetState) { state in
            router.updateBottomSheetState(state)
        }
        .onChange(of: router.listPresentationRequestID) { _ in
            presentBottomSheet()
        }
        .onChange(of: placeList.shouldAutoExpandAfterResearch) { shouldExpand in
            guard shouldExpand else { return }
            showResearchResultsSheet()
            homeStore.send(.bottomSheet(.placeList(.consumeAutoExpandAfterResearch)))
        }
    }

    private var bottomSheetState: HomeBottomSheetState { homeStore.state.bottomSheet.bottomSheetState }
    private var selectedItem: RodiCourseItem? { homeStore.state.bottomSheet.selectedItem }
    private var selectedPlaceDetail: PlaceDetail? { homeStore.state.bottomSheet.placeDetail }
    private var isPlaceDetailLoading: Bool { homeStore.state.bottomSheet.isPlaceDetailLoading }
    private var isBookmarkUpdating: Bool { homeStore.state.bottomSheet.isBookmarkUpdating }
    private var selectedRouteOverlay: RodiRouteOverlay? { homeStore.state.bottomSheet.selectedRouteOverlay }
    private var isRouteLoading: Bool { homeStore.state.bottomSheet.isRouteLoading }
    private var routeStatusMessage: String? { homeStore.state.bottomSheet.routeStatusMessage }
    private var placeList: HomeBottomSheetReducer.State.PlaceListState { homeStore.state.bottomSheet.placeList }
    private var userLocationCoordinate: RodiCoordinate? { homeStore.state.map.userLocationCoordinate }
    private var hasLocationPermission: Bool { homeStore.state.map.hasLocationPermission }
    private var isCurrentLocationButtonActive: Bool { homeStore.state.map.isCurrentLocationButtonActive }
    private var shouldRenderMap: Bool { homeStore.state.map.shouldRender }
    private var overlayState: HomeOverlayState? { homeStore.state.overlayState }

    private var bottomSheetContentState: CourseBottomSheetContentState {
        CourseBottomSheetContentState(
            placeItems: placeList.items,
            selectedItem: selectedItem,
            selectedPlaceDetail: selectedPlaceDetail,
            isPlaceDetailLoading: isPlaceDetailLoading,
            isBookmarkUpdating: isBookmarkUpdating,
            isRouteLoading: isRouteLoading,
            routeStatusMessage: routeStatusMessage,
            userLocation: userLocationCoordinate,
            hasLocationPermission: hasLocationPermission,
            isInitialLoading: placeList.isInitialLoading,
            isNextPageLoading: placeList.isNextPageLoading,
            listErrorMessage: placeList.errorMessage,
            hasNextPage: placeList.hasNext,
            pageProgress: hasFixedBottomSheet ? 0 : pageProgress,
            isExpanded: bottomSheetState == .expanded
        )
    }

    private var bottomSheetActions: CourseBottomSheetActions {
        CourseBottomSheetActions(
            selectPlaceItem: handlePlaceListSelection,
            clearSelection: clearSelectedCourse,
            showRouteGuidanceMessage: showRouteGuidanceMessage,
            requestLocationPermission: showLocationSettingsAlert,
            toggleBookmark: { homeStore.send(.bottomSheet(.selection(.toggleBookmark))) },
            reloadPlaceList: reloadPlaceList,
            loadNextPage: loadNextPlaceListPage,
            expand: expandBottomSheet,
            collapse: collapseBottomSheet
        )
    }

    private var pageMorphOverlay: some View {
        RodiColor.white
            .ignoresSafeArea()
            .opacity(pageProgress)
            .allowsHitTesting(false)
            .zIndex(0.5)
    }

    private var listButtonLayer: some View {
        Group {
            if bottomSheetState != .expanded, !hasSelectedBottomSheet, shouldRenderMap {
                VStack {
                    Spacer()
                    HomeListButton(action: presentBottomSheet)
                        .padding(.bottom, Constants.bottomTabBarHeight + 16)
                        .opacity(bottomTabBarOpacity)
                        .offset(y: bottomTabBarOffset)
                        .animation(.easeOut(duration: 0.18), value: bottomSheetState)
                        .allowsHitTesting(bottomTabBarOpacity > 0.95)
                }
                .transition(.opacity)
                .zIndex(0.8)
            }
        }
    }

    private var bottomSheetLayer: some View {
        HomeBottomSheetLayer(
            content: bottomSheetContentState,
            actions: bottomSheetActions,
            height: renderedSheetHeight,
            visibleHeight: visibleSheetHeight,
            usesIntrinsicHeight: usesContentSizedSelectedDetail,
            offsetY: renderedSheetOffset,
            opacity: bottomSheetOpacity,
            dragGesture: sheetDragGesture,
            shouldAllowDrag: shouldAllowSheetDrag,
            showsCourseDetailLocationControl: usesContentSizedSelectedDetail,
            isCurrentLocationActive: isCurrentLocationButtonActive,
            currentLocationAction: requestCurrentLocationFromCourseDetail,
            contentHeightAction: { height in
                guard abs(selectedSheetContentHeight - height) > 0.5 else { return }
                selectedSheetContentHeight = height
            }
        )
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named(Constants.dragCoordinateSpace))
            .updating($sheetDragTranslation) { value, state, _ in
                state = hasSelectedBottomSheet
                    ? max(value.translation.height, 0)
                    : value.translation.height
            }
            .onEnded { value in
                handleSheetDragEnded(translation: value.translation.height)
            }
    }

    private var sheetLayout: HomeBottomSheetLayoutPolicy {
        HomeBottomSheetLayoutPolicy(
            sheetHeight: homeStore.state.bottomSheet.sheetHeight,
            dragTranslation: sheetDragTranslation,
            settlingSheetHeight: settlingSheetHeight,
            hasSelectedBottomSheet: hasSelectedBottomSheet,
            usesCompactSelectedDetail: selectedPlaceDetail?.type == .course && !isPlaceDetailLoading,
            selectedSheetContentHeight: selectedSheetContentHeight,
            bottomSheetState: bottomSheetState,
            sheetHeightRatio: Constants.sheetHeightRatio,
            floatingControlSpacing: Constants.floatingControlSpacing,
            currentLocationButtonSize: Constants.currentLocationButtonSize,
            pageMorphStartRatio: Constants.pageMorphStartRatio,
            expandedSheetSnapRatio: Constants.expandedSheetSnapRatio,
            collapsedSheetSnapRatio: Constants.collapsedSheetSnapRatio,
            bottomTabBarHeight: Constants.bottomTabBarHeight
        )
    }

    private var mediumSheetHeight: CGFloat { sheetLayout.mediumSheetHeight }
    private var hasSelectedBottomSheet: Bool { selectedItem != nil }
    private var hasFixedBottomSheet: Bool { sheetLayout.hasFixedBottomSheet }
    private var usesContentSizedSelectedDetail: Bool { selectedPlaceDetail?.type == .course && !isPlaceDetailLoading }
    private var mapVisibilityState: RodiMapVisibilityState { bottomSheetState == .expanded ? .covered : .interactive }
    private var shouldShowPlaceResearchButton: Bool {
        placeList.needsResearch && overlayState == nil && shouldRenderMap && bottomSheetState != .expanded && !hasSelectedBottomSheet
    }
    private var availableSheetHeight: CGFloat { sheetLayout.availableSheetHeight }
    private var renderedSheetHeight: CGFloat { sheetLayout.renderedSheetHeight }
    private var visibleSheetHeight: CGFloat { hasFixedBottomSheet ? sheetLayout.fixedSheetHeight : sheetLayout.currentSheetHeight }
    private var renderedSheetOffset: CGFloat { sheetLayout.renderedSheetOffset + selectedDetailDismissOffset }
    private var selectedDetailDismissOffset: CGFloat {
        guard hasFixedBottomSheet else { return 0 }
        return selectedDetailSettlingOffset ?? max(sheetDragTranslation, 0)
    }
    private var shouldAllowSheetDrag: Bool {
        settlingSheetHeight == nil && selectedDetailSettlingOffset == nil && (sheetLayout.shouldAllowSheetDrag || hasSelectedBottomSheet)
    }
    private var selectedDetailDismissOpacity: CGFloat {
        guard hasFixedBottomSheet else { return 1 }
        return 1 - min(selectedDetailDismissOffset / max(sheetLayout.fixedSheetHeight, 1), 1)
    }
    private var floatingControlBottomInset: CGFloat {
        let inset = sheetLayout.floatingControlBottomInset
        guard hasFixedBottomSheet else { return inset }
        return max(Constants.bottomTabBarHeight + Constants.floatingControlSpacing, inset - selectedDetailDismissOffset)
    }
    private var cameraObscuredBottomInset: CGFloat {
        if bottomSheetState == .collapsed { return Constants.bottomTabBarHeight }
        if shouldAllowSheetDrag { return mediumSheetHeight }
        return hasFixedBottomSheet ? sheetLayout.fixedSheetHeight : sheetLayout.currentSheetHeight
    }
    private var locationButtonOpacity: CGFloat { sheetLayout.locationButtonOpacity }
    private var bottomTabBarOpacity: CGFloat { sheetLayout.bottomTabBarOpacity }
    private var bottomTabBarOffset: CGFloat { sheetLayout.bottomTabBarOffset }
    private var bottomSheetOpacity: CGFloat { sheetLayout.bottomSheetOpacity * selectedDetailDismissOpacity }
    private var pageProgress: CGFloat { sheetLayout.pageProgress }

    private func handleMapOutput(_ output: HomeMapView.Output) {
        switch output {
        case .mapReady:
            consumePendingPlaceSelectionIfNeeded()
        case .markerSelected(let item):
            withAnimation(.easeOut(duration: 0.22)) {
                homeStore.send(.bottomSheet(.selection(.selectMapItem(item, mediumHeight: mediumSheetHeight))))
            }
        case .viewportChanged(let viewport, let center, let isUserInitiated):
            homeStore.send(.bottomSheet(.placeList(.viewportChanged(viewport: viewport, center: center, isUserInitiated: isUserInitiated))))
        case .selectionInvalidated:
            homeStore.send(.bottomSheet(.selection(.clear)))
        case .initialPlaceListSearchPrepared(let origin):
            homeStore.send(.map(.delegate(.prepareInitialPlaceListSearch(origin: origin))))
        case .locationNotice(let message):
            homeStore.send(.presentation(.showSnackbar(message)))
        case .locationSettingsRequested:
            homeStore.send(.presentation(.showLocationSettingsAlert))
        case .researchRequested:
            reloadPlaceList()
        }
    }

    private func handleSheetDragEnded(translation: CGFloat) {
        guard bottomSheetState == .medium else { return }
        if hasSelectedBottomSheet {
            settleSelectedDetailAfterDrag(translation: translation)
            return
        }
        let destination = sheetLayout.sheetStateAfterDrag(translation: translation)
        settleBottomSheet(from: sheetLayout.height(forDragTranslation: translation), to: destination)
    }

    private func settleSelectedDetailAfterDrag(translation: CGFloat) {
        let currentOffset = max(translation, 0)
        let shouldDismiss = currentOffset >= Constants.selectedDetailDismissThreshold
        let targetOffset = shouldDismiss ? sheetLayout.fixedSheetHeight + 24 : 0
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { selectedDetailSettlingOffset = currentOffset }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: Constants.selectedDetailDismissSnapDuration)) {
                selectedDetailSettlingOffset = targetOffset
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(Constants.selectedDetailDismissSnapDuration * 1_000)))
            var completion = Transaction()
            completion.disablesAnimations = true
            withTransaction(completion) {
                if shouldDismiss {
                    homeStore.send(.bottomSheet(.selection(.clear)))
                    homeStore.send(.bottomSheet(.sheet(.dismiss)))
                }
                selectedDetailSettlingOffset = nil
            }
        }
    }

    private func settleBottomSheet(from currentHeight: CGFloat, to destination: HomeBottomSheetState) {
        let settlingID = UUID()
        sheetSettlingID = settlingID
        let duration = destination == .collapsed ? Constants.collapsedSheetSnapDuration : Constants.defaultSheetSnapDuration
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { settlingSheetHeight = currentHeight }
        let targetHeight = destination == .collapsed ? 0 : destination == .medium ? mediumSheetHeight : availableSheetHeight
        DispatchQueue.main.async {
            guard sheetSettlingID == settlingID else { return }
            withAnimation(.easeOut(duration: duration)) { settlingSheetHeight = targetHeight }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(duration * 1_000)))
            guard sheetSettlingID == settlingID else { return }
            var completion = Transaction()
            completion.disablesAnimations = true
            withTransaction(completion) {
                switch destination {
                case .collapsed: homeStore.send(.bottomSheet(.sheet(.dismiss)))
                case .medium: homeStore.send(.bottomSheet(.sheet(.collapse(mediumHeight: mediumSheetHeight))))
                case .expanded: homeStore.send(.bottomSheet(.sheet(.expand(availableHeight: availableSheetHeight))))
                }
                settlingSheetHeight = nil
            }
        }
    }

    private func presentBottomSheet() {
        guard bottomSheetState == .collapsed else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            homeStore.send(.bottomSheet(.sheet(.present(mediumHeight: mediumSheetHeight))))
        }
    }

    private func showResearchResultsSheet() {
        switch bottomSheetState {
        case .collapsed: presentBottomSheet()
        case .expanded: collapseBottomSheet()
        case .medium: break
        }
    }

    private func expandBottomSheet() {
        guard bottomSheetState != .expanded else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            homeStore.send(.bottomSheet(.sheet(.expand(availableHeight: availableSheetHeight))))
        }
    }

    private func collapseBottomSheet() {
        guard bottomSheetState != .collapsed else { return }
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            homeStore.send(.bottomSheet(.sheet(.collapse(mediumHeight: mediumSheetHeight))))
        }
    }

    private func clearSelectedCourse() {
        withAnimation(.easeOut(duration: 0.2)) {
            homeStore.send(.bottomSheet(.selection(.clear)))
            homeStore.send(.bottomSheet(.sheet(.dismiss)))
        }
    }

    private func handlePlaceListSelection(_ item: PlaceListItem) {
        withAnimation(.easeOut(duration: 0.22)) {
            homeStore.send(.bottomSheet(.selection(.selectItem(RodiCourseItem(placeListItem: item), mediumHeight: mediumSheetHeight))))
        }
    }

    private func consumePendingPlaceSelectionIfNeeded() {
        guard isHomeTabSelected(), homeStore.state.map.isReady, let placeID = router.consumePendingPlaceID() else { return }
        RodiLogger.info("Saved place selection handed off to ready home map placeID=\(placeID)")
        homeStore.send(.bottomSheet(.selection(.selectPlaceID(placeID, mediumHeight: mediumSheetHeight))))
    }

    private func reloadPlaceList() {
        homeStore.send(.bottomSheet(.placeList(.reloadCurrentViewport(origin: userLocationCoordinate))))
    }

    private func loadNextPlaceListPage() {
        homeStore.send(.bottomSheet(.placeList(.loadNextPage)))
    }

    private func showRouteGuidanceMessage(_ message: String) {
        homeStore.send(.presentation(.showSnackbar(message)))
    }

    private func requestCurrentLocationFromCourseDetail() {
        homeStore.send(.bottomSheet(.selection(.clear)))
        homeStore.send(.bottomSheet(.sheet(.resetToMedium(mediumHeight: mediumSheetHeight))))
        homeStore.send(.map(.requestCurrentLocation))
    }

    private func showLocationSettingsAlert() {
        homeStore.send(.presentation(.showLocationSettingsAlert))
    }
}
