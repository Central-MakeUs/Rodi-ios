//
//  HomeBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct HomeBottomSheetView: View {
    @ObservedObject private var homeStore: StoreOf<HomeReducer>
    @ObservedObject private var router: HomeRouter
    private let isHomeTabSelected: () -> Bool
    private let onSearchRequested: () -> Void
    private let bottomTabBarHeight: CGFloat
    private let placeRepository: PlaceRepository

    @GestureState private var sheetDragTranslation: CGFloat = 0
    private let dragCoordinateSpace = "rodi.home.bottom-sheet.drag"

    init(
        homeStore: StoreOf<HomeReducer>,
        router: HomeRouter,
        isHomeTabSelected: @escaping () -> Bool,
        onSearchRequested: @escaping () -> Void,
        bottomTabBarHeight: CGFloat,
        placeRepository: PlaceRepository
    ) {
        self.homeStore = homeStore
        self.router = router
        self.isHomeTabSelected = isHomeTabSelected
        self.onSearchRequested = onSearchRequested
        self.bottomTabBarHeight = bottomTabBarHeight
        self.placeRepository = placeRepository
    }

    var body: some View {
        GeometryReader { proxy in
            HomeMapView(
                homeStore: homeStore,
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
                    isResearchLoading: placeList.isManualResearchLoading,
                    selectedSearchResultName: router.selectedSearchResultName
                ),
                onOutput: handleMapOutput
            ) {
                mapOverlay
            }
            .onAppear {
                reportContainerHeight(proxy.size.height)
            }
            .onChange(of: proxy.size.height) { height in
                reportContainerHeight(height)
            }
        }
        .coordinateSpace(name: dragCoordinateSpace)
        .onAppear {
            consumePendingPlaceSelectionIfNeeded()
        }
        .animation(.easeOut(duration: 0.25), value: bottomSheetState)
        .onChange(of: router.pendingPlaceID) { _ in
            consumePendingPlaceSelectionIfNeeded()
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
    private var filterState: HomePracticeFilterReducer.State { homeStore.state.bottomSheet.filter }
    private var isFilterPresented: Bool { homeStore.state.bottomSheet.manager.isFilterPresented }
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
            isFilterPresented: isFilterPresented,
            filterSelection: filterState.draftSelection,
            isFilterApplying: filterState.isApplying,
            canApplyFilter: filterState.canApply,
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
            collapse: collapseBottomSheet,
            presentFilter: presentFilter,
            resetFilter: { homeStore.send(.bottomSheet(.filter(.reset))) },
            selectFilterCategory: { category in
                homeStore.send(.bottomSheet(.filter(.selectCategory(category))))
            },
            toggleFilterType: { type in
                homeStore.send(.bottomSheet(.filter(.toggleType(type))))
            },
            selectAllFilterTypes: {
                homeStore.send(.bottomSheet(.filter(.selectAll)))
            },
            applyFilter: {
                homeStore.send(.bottomSheet(.filter(.apply)))
            },
            closeFilter: dismissFilter
        )
    }

    private var pageMorphOverlay: some View {
        RodiColor.white
            .ignoresSafeArea()
            .opacity(pageProgress)
            .allowsHitTesting(false)
            .zIndex(0.5)
    }

    private var mapOverlay: some View {
        ZStack(alignment: .bottom) {
            pageMorphOverlay
            listButtonLayer
            bottomSheetLayer
        }
    }

    private var listButtonLayer: some View {
        Group {
            if bottomSheetState != .expanded, !hasSelectedBottomSheet, shouldRenderMap {
                VStack {
                    Spacer()
                    HomeListButton(action: presentBottomSheet)
                        .padding(.bottom, listButtonBottomInset)
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
                reportSelectedContentHeight(height)
            }
        )
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named(dragCoordinateSpace))
            .updating($sheetDragTranslation) { value, state, _ in
                state = hasSelectedBottomSheet || isFilterPresented
                    ? max(value.translation.height, 0)
                    : value.translation.height
            }
            .onEnded { value in
                handleSheetDragEnded(translation: value.translation.height)
            }
    }

    private var sheetLayout: HomeBottomSheetLayoutPolicy {
        HomeBottomSheetLayoutPolicy(
            containerHeight: homeStore.state.bottomSheet.manager.containerHeight,
            sheetHeight: homeStore.state.bottomSheet.sheetHeight,
            dragTranslation: sheetDragTranslation,
            hasSelectedBottomSheet: hasSelectedBottomSheet,
            usesCompactSelectedDetail: selectedPlaceDetail?.type == .course && !isPlaceDetailLoading,
            selectedSheetContentHeight: homeStore.state.bottomSheet.manager.selectedContentHeight,
            bottomSheetState: bottomSheetState,
            bottomTabBarHeight: bottomTabBarHeight
        )
    }

    private var mediumSheetHeight: CGFloat { sheetLayout.mediumSheetHeight }
    private var listButtonBottomInset: CGFloat { sheetLayout.listButtonBottomInset }
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
        return max(sheetDragTranslation, 0)
    }
    private var shouldAllowSheetDrag: Bool {
        sheetLayout.shouldAllowSheetDrag || hasSelectedBottomSheet
    }
    private var selectedDetailDismissOpacity: CGFloat {
        guard hasFixedBottomSheet else { return 1 }
        return 1 - min(selectedDetailDismissOffset / max(sheetLayout.fixedSheetHeight, 1), 1)
    }
    private var floatingControlBottomInset: CGFloat {
        let inset = sheetLayout.floatingControlBottomInset
        guard hasFixedBottomSheet else { return inset }
        return max(bottomTabBarHeight + sheetLayout.metrics.floatingControlSpacing, inset - selectedDetailDismissOffset)
    }
    private var cameraObscuredBottomInset: CGFloat {
        if bottomSheetState == .collapsed { return bottomTabBarHeight }
        if shouldAllowSheetDrag { return mediumSheetHeight }
        return hasFixedBottomSheet ? sheetLayout.fixedSheetHeight : sheetLayout.currentSheetHeight
    }
    private var locationButtonOpacity: CGFloat { sheetLayout.locationButtonOpacity }
    private var bottomTabBarOpacity: CGFloat { sheetLayout.bottomTabBarOpacity }
    private var bottomTabBarOffset: CGFloat { sheetLayout.bottomTabBarOffset }
    private var bottomSheetOpacity: CGFloat {
        sheetLayout.bottomSheetOpacity * selectedDetailDismissOpacity
    }
    private var pageProgress: CGFloat { sheetLayout.pageProgress }

    private func handleMapOutput(_ output: HomeMapOutput) {
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
        case .searchRequested:
            onSearchRequested()
        case .searchSelectionCleared:
            router.clearSelectedSearchResult()
        }
    }

    private func handleSheetDragEnded(translation: CGFloat) {
        guard bottomSheetState == .medium else { return }
        if hasSelectedBottomSheet {
            guard sheetLayout.shouldDismissDetail(after: translation) else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                homeStore.send(.bottomSheet(.selection(.clear)))
                homeStore.send(.bottomSheet(.manager(.dismissSheet)))
            }
            router.clearSelectedPlaceSearchResult()
            return
        }
        if isFilterPresented {
            guard sheetLayout.shouldDismissFilter(after: translation) else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                homeStore.send(.bottomSheet(.manager(.dismissFilter(mediumHeight: mediumSheetHeight))))
            }
            return
        }
        switch sheetLayout.sheetStateAfterDrag(translation: translation) {
        case .collapsed:
            withAnimation(.easeOut(duration: 0.18)) {
                homeStore.send(.bottomSheet(.manager(.dismissSheet)))
            }
        case .medium:
            withAnimation(.easeOut(duration: 0.25)) {
                homeStore.send(.bottomSheet(.manager(.collapse(mediumHeight: mediumSheetHeight))))
            }
        case .expanded:
            withAnimation(.easeOut(duration: 0.25)) {
                homeStore.send(.bottomSheet(.manager(.expand(availableHeight: availableSheetHeight))))
            }
        }
    }

    private func presentBottomSheet() {
        guard bottomSheetState == .collapsed else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            homeStore.send(.bottomSheet(.manager(.presentList(mediumHeight: mediumSheetHeight))))
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
            homeStore.send(.bottomSheet(.manager(.expand(availableHeight: availableSheetHeight))))
        }
    }

    private func presentFilter() {
        homeStore.send(.bottomSheet(.filter(.present(mediumHeight: mediumSheetHeight))))
    }

    private func dismissFilter() {
        homeStore.send(.bottomSheet(.manager(.dismissFilter(mediumHeight: mediumSheetHeight))))
    }

    private func collapseBottomSheet() {
        guard bottomSheetState != .collapsed else { return }
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            homeStore.send(.bottomSheet(.manager(.collapse(mediumHeight: mediumSheetHeight))))
        }
    }

    private func clearSelectedCourse() {
        withAnimation(.easeOut(duration: 0.2)) {
            homeStore.send(.bottomSheet(.selection(.clear)))
            homeStore.send(.bottomSheet(.manager(.dismissSheet)))
            router.clearSelectedPlaceSearchResult()
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
        homeStore.send(.bottomSheet(.manager(.resetToMedium(mediumHeight: mediumSheetHeight))))
        router.clearSelectedPlaceSearchResult()
        homeStore.send(.map(.requestCurrentLocation))
    }

    private func showLocationSettingsAlert() {
        homeStore.send(.presentation(.showLocationSettingsAlert))
    }

    private func reportContainerHeight(_ height: CGFloat) {
        let currentHeight = homeStore.state.bottomSheet.manager.containerHeight
        guard abs(currentHeight - height) > 0.5 else { return }
        homeStore.send(.bottomSheet(.manager(.containerHeightChanged(height))))
    }

    private func reportSelectedContentHeight(_ height: CGFloat) {
        let currentHeight = homeStore.state.bottomSheet.manager.selectedContentHeight
        guard abs(currentHeight - height) > 0.5 else { return }
        homeStore.send(.bottomSheet(.manager(.selectedContentHeightChanged(height))))
    }
}


