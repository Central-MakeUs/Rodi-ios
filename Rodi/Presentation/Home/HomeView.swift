//
//  HomeView.swift
//  Rodi
//
//  Created by mac on 8/5/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.screenBounds) private var screenBounds
    @Environment(\.screenSafeAreaInsets) private var screenSafeAreaInsets
    @EnvironmentObject private var networkConnectionMonitor: NetworkConnectionMonitor

    @StateObject private var store: StoreOf<HomeReducer>
    @ObservedObject private var snackbarService: SnackbarService
    @State private var courseBottomSheetHeight: CGFloat = 180
    @State private var parkingBottomSheetHeight: CGFloat = 180
    @State private var transientBottomSheetHeight: CGFloat?
    @State private var handledListPresentationRequestID = 0
    @State private var handledPlaceSelectionRequestID = 0
    @State private var handledReviewFlowFinishedRequestID = 0
    @State private var isAwaitingLiveActivitySettingsReturn = false
    @State private var isMapNetworkUnavailableScreenPresented = false

    private let presentation: HomePresentation
    private let bottomTabBarHeight: CGFloat
    private let dependencies: HomeFeatureDependencies

    init(
        presentation: HomePresentation,
        bottomTabBarHeight: CGFloat,
        dependencies: HomeFeatureDependencies
    ) {
        self.presentation = presentation
        self.bottomTabBarHeight = bottomTabBarHeight
        self.dependencies = dependencies

        _snackbarService = ObservedObject(wrappedValue: dependencies.snackbarService)
        _store = StateObject(wrappedValue: Store(
            state: HomeReducer.State(),
            reducer: HomeReducer(
                dependencies: .init(
                    tokenStore: dependencies.tokenStore,
                    placeRepository: dependencies.placeRepository,
                    practiceRepository: dependencies.practiceRepository,
                    recentSearchRepository: dependencies.recentSearchRepository,
                    reviewRepository: dependencies.reviewRepository,
                    memberRepository: dependencies.memberRepository,
                    practiceMeasurementStore: dependencies.practiceMeasurementStore,
                    practiceTrackingService: dependencies.practiceTrackingService
                ),
                delegateHandler: presentation.handleDelegate
            )
        ))
    }

    var body: some View {
        HomePresentationHost(
            isSearchPresented: searchPresentationBinding,
            isExpandedPresented: courseDetailExpandedPresentationBinding,
            isReviewPresented: courseDetailReviewPresentationBinding,
            onExpandedDismiss: handleCourseDetailExpandedPresentationDismissed,
            snackbarMessage: snackbarService.message
        ) {
            core
        } searchContent: {
            if let origin = store.state.presentation.searchOrigin {
                HomeSearchView(
                    origin: origin,
                    state: store.state.search,
                    send: { store.send(.search($0)) }
                )
            }
        } expandedContent: {
            CourseDetailBottomSheetView(
                state: store.state.bottomSheet.courseDetail,
                send: { store.send(.bottomSheet(.courseDetail($0))) },
                userLocation: store.state.map.userLocation,
                hasLocationPermission: store.state.map.locationAuthorizationState == .authorized,
                requestLocationPermission: {
                    store.send(.presentation(.setLocationSettingsAlertPresented(true)))
                },
                renderingMode: .expanded,
                expandedBackAction: {
                    store.send(.bottomSheet(.courseDetail(.collapseRequested)))
                }
            )
        } routeGuidanceContent: {
            routeGuidanceOverlay
        } reviewContent: {
            ReviewView(
                state: presentation.courseDetailReviewPresentation.state,
                send: presentation.courseDetailReviewPresentation.send
            )
            .rodiSnackbar(message: presentation.courseDetailReviewPresentation.snackbarMessage)
        }
            .onAppear {
                store.send(.map(.tabSelectionChanged(presentation.isHomeTabSelected)))
                handleScenePhase(scenePhase)
                presentation.bottomTabBarVisibilityChanged(store.state.presentation.isBottomTabBarVisible)
                handleListPresentationRequest(presentation.listPresentationRequestID)
                handlePlaceSelection(presentation.placeSelectionRequest)
                handleReviewFlowFinished(presentation.reviewFlowFinishedRequestID)
            }
            .alert("위치 접근 권한이 필요해요", isPresented: locationSettingsAlertBinding) {
                Button("취소", role: .cancel) {}
                Button("확인") {
                    Task { @MainActor in
                        AppSettings.openSetting()
                    }
                }
            } message: {
                Text("현 위치 기반 기능을 사용하려면 설정에서 위치 접근을 '앱을 사용하는 동안 허용'으로 변경해주세요.")
            }
            .rodiSnackbar(message: snackbarService.message)
            .onChange(of: store.state.presentation.pendingSnackbar) { snackbar in
                guard let snackbar else { return }
                snackbarService.show(snackbar)
                store.send(.presentation(.snackbarRequestHandled))
            }
            .onChange(of: store.state.presentation.isBottomTabBarVisible) {
                presentation.bottomTabBarVisibilityChanged($0)
            }
            .onChange(of: presentation.isHomeTabSelected) { isSelected in
                store.send(.map(.tabSelectionChanged(isSelected)))
            }
            .onChange(of: scenePhase) { phase in
                handleScenePhase(phase)
            }
            .onChange(of: presentation.listPresentationRequestID) { requestID in
                handleListPresentationRequest(requestID)
            }
            .onChange(of: presentation.placeSelectionRequest) { request in
                handlePlaceSelection(request)
            }
            .onChange(of: presentation.reviewFlowFinishedRequestID) { requestID in
                handleReviewFlowFinished(requestID)
            }
            .task(id: shouldDelayMapNetworkUnavailableScreen) {
                guard shouldDelayMapNetworkUnavailableScreen else {
                    isMapNetworkUnavailableScreenPresented = false
                    return
                }

                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                } catch {
                    return
                }

                guard !Task.isCancelled,
                      shouldDelayMapNetworkUnavailableScreen
                else {
                    return
                }
                isMapNetworkUnavailableScreenPresented = true
            }
    }
}

private struct HomePlaceLoadingIndicator: View {
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(RodiColor.primary)
                    .frame(width: 8, height: 8)
                    .opacity(index == activeIndex ? 1 : 0.28)
                    .scaleEffect(index == activeIndex ? 1 : 0.72)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeIndex)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 260_000_000)
                guard !Task.isCancelled else { return }
                activeIndex = (activeIndex + 1) % 3
            }
        }
        .accessibilityLabel("장소 정보 로딩 중")
    }
}


// MARK: - Core
extension HomeView {

    private var routeGuidanceOverlay: some View {
        HomeRouteGuidanceOverlay(
            presentation: routeGuidancePresentation,
            routeOnlyAction: sendRouteGuidanceRouteOnly,
            openSettingsAction: {
                isAwaitingLiveActivitySettingsReturn = true
                AppSettings.openSetting()
            },
            closeAction: sendRouteGuidanceDismissed,
            appSelectedAction: sendRouteGuidanceAppSelected,
            installSelectedAction: sendRouteGuidanceInstallSelected,
            activeMeasurementEndedAction: sendRouteGuidanceActiveMeasurementEnded
        )
    }

    private var routeGuidancePresentation: RouteGuidanceFlowPresentation? {
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.state.bottomSheet.courseDetail.routeGuidancePresentation
        case .parkingDetail:
            store.state.bottomSheet.parkingDetail.routeGuidancePresentation
        case .recommendList, .filter:
            nil
        }
    }

    private func sendRouteGuidanceAppSelected(_ app: RouteGuidanceApp, rememberSelection: Bool) {
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.send(.bottomSheet(.courseDetail(.routeGuidanceAppSelected(app, rememberSelection: rememberSelection))))
        case .parkingDetail:
            store.send(.bottomSheet(.parkingDetail(.routeGuidanceAppSelected(app, rememberSelection: rememberSelection))))
        case .recommendList, .filter:
            break
        }
    }

    private func sendRouteGuidanceInstallSelected(_ app: RouteGuidanceApp) {
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.send(.bottomSheet(.courseDetail(.routeGuidanceInstallSelected(app))))
        case .parkingDetail:
            store.send(.bottomSheet(.parkingDetail(.routeGuidanceInstallSelected(app))))
        case .recommendList, .filter:
            break
        }
    }

    private func sendRouteGuidanceRouteOnly() {
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.send(.bottomSheet(.courseDetail(.routeGuidanceRouteOnlySelected)))
        case .parkingDetail:
            store.send(.bottomSheet(.parkingDetail(.routeGuidanceRouteOnlySelected)))
        case .recommendList, .filter:
            break
        }
    }

    private func sendRouteGuidanceActiveMeasurementEnded() {
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.send(.bottomSheet(.courseDetail(.routeGuidanceActiveMeasurementEnded)))
        case .parkingDetail:
            store.send(.bottomSheet(.parkingDetail(.routeGuidanceActiveMeasurementEnded)))
        case .recommendList, .filter:
            break
        }
    }

    private func sendRouteGuidanceDismissed() {
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.send(.bottomSheet(.courseDetail(.routeGuidanceDismissed)))
        case .parkingDetail:
            store.send(.bottomSheet(.parkingDetail(.routeGuidanceDismissed)))
        case .recommendList, .filter:
            break
        }
    }

    private var core: some View {
        ZStack(alignment: .bottom) {
            if store.state.map.mapLifecycle != .inactive {
                kakaoMapView()
            }

            if isInitialMapPresentationReady {
                mapControls()

                if isFilterPresented {
                    RodiColor.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.send(.bottomSheet(.filter(.dismiss)))
                        }
                        .accessibilityHidden(true)
                }

                HomeBottomSheetView(
                    state: store.state.bottomSheet,
                    send: { store.send(.bottomSheet($0)) },
                    userLocation: store.state.map.userLocation,
                    hasLocationPermission: store.state.map.locationAuthorizationState == .authorized,
                    bottomTabBarHeight: bottomTabBarHeight,
                    onCourseDetailHeightChanged: { height in
                        guard abs(courseBottomSheetHeight - height) > 0.5 else { return }
                        courseBottomSheetHeight = height
                    },
                    onParkingDetailHeightChanged: { height in
                        guard abs(parkingBottomSheetHeight - height) > 0.5 else { return }
                        parkingBottomSheetHeight = height
                    },
                    onVisibleHeightChanged: { height, isTransient in
                        transientBottomSheetHeight = isTransient ? height : nil
                    },
                    onCourseExpansionSettled: presentExpandedCourseDetail,
                    requestLocationPermission: {
                        store.send(.presentation(.setLocationSettingsAlertPresented(true)))
                    },
                    debugReviewTestAction: debugReviewTestAction,
                    debugHardWithdrawAction: {
                        try await dependencies.memberRepository.hardWithdraw()
                    }
                )
            } else {
                initialMapLoadingView
            }

            if isSavedPlaceLoading {
                savedPlaceLoadingOverlay
            }

            if isMapNetworkUnavailableScreenPresented {
                MapNetworkUnavailableView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shouldDelayMapNetworkUnavailableScreen: Bool {
        presentation.isHomeTabSelected
            && scenePhase == .active
            && networkConnectionMonitor.status == .disconnected
    }

    private func handleListPresentationRequest(_ requestID: Int) {
        guard requestID > handledListPresentationRequestID else { return }
        handledListPresentationRequestID = requestID
        store.send(.bottomSheet(.showRecommendList))
        store.send(.bottomSheet(.recommendList(.present)))
    }

    private func handlePlaceSelection(_ request: HomePlaceSelectionRequest?) {
        guard let request,
              request.id > handledPlaceSelectionRequestID
        else {
            return
        }
        handledPlaceSelectionRequestID = request.id
        store.send(.map(.savedPlaceSelected(request.place)))
        presentation.placeSelectionHandled(request.id)
    }

    private func handleReviewFlowFinished(_ requestID: Int) {
        guard requestID > handledReviewFlowFinishedRequestID else { return }
        handledReviewFlowFinishedRequestID = requestID
        store.send(.bottomSheet(.reviewFlowFinished))
    }

    private func presentExpandedCourseDetail() {
        guard store.state.bottomSheet.courseDetail.presentation == .sheet else { return }
        store.send(.bottomSheet(.courseDetail(.expandRequested)))
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        store.send(.map(.activityChanged(phase == .active)))
        guard phase == .active else { return }
        store.send(.map(.locationAuthorizationRefreshRequested))
        guard isAwaitingLiveActivitySettingsReturn else { return }
        isAwaitingLiveActivitySettingsReturn = false
        switch store.state.bottomSheet.route {
        case .courseDetail:
            store.send(.bottomSheet(.courseDetail(.routeGuidanceSettingsReturned)))
        case .parkingDetail:
            store.send(.bottomSheet(.parkingDetail(.routeGuidanceSettingsReturned)))
        case .recommendList, .filter:
            break
        }
    }
}

private extension HomeView {
    var debugReviewTestAction: () -> Void {
        #if DEBUG
        return { store.send(.debugReviewTestRequested) }
        #else
        return {}
        #endif
    }
}


// MARK: - Layout
extension HomeView {

    private var screenHeight: CGFloat {
        screenBounds?.height ?? 0
    }

    private var isInitialMapPresentationReady: Bool {
        let map = store.state.map
        let hasRenderedMarkers = map.markerState == .failed
            || (map.markerState == .loaded && map.hasCompletedInitialMarkerRendering)

        return map.mapLifecycle == .ready
            && map.hasCompletedInitialLocationResolution
            && hasRenderedMarkers
    }

    private var isFilterPresented: Bool {
        store.state.bottomSheet.route == .filter
    }

    private var isSavedPlaceLoading: Bool {
        let bottomSheet = store.state.bottomSheet
        return bottomSheet.isSavedPlaceResolution && bottomSheet.resolvingPlaceID != nil
    }

    private var savedPlaceLoadingOverlay: some View {
        ZStack {
            RodiColor.black.opacity(0.16)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                HomePlaceLoadingIndicator()

                Text("장소 정보를 불러오고 있어요")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)

                Text("잠시만 기다려 주세요.")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: RodiColor.black.opacity(0.12), radius: 12, y: 4)
        }
        .transition(.opacity)
        .zIndex(2)
    }

    private var initialMapLoadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
                .tint(RodiColor.primary)

            Text("지도를 불러오고 있어요")
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)

            Text("잠시만 기다려 주세요.")
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray700)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RodiColor.white)
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
    }

    private func kakaoMapView() -> some View {
        KakaoMapContainerView(
            cameraTarget: store.state.map.cameraTarget,
            cameraRequestID: store.state.map.cameraRequestID,
            animatedCameraRequestID: store.state.map.animatedCameraRequestID,
            cameraFocus: store.state.map.cameraFocus,
            userLocation: store.state.map.userLocation,
            userHeadingDegrees: store.state.map.userHeadingDegrees,
            routeOverlay: store.state.map.routeOverlay,
            mapMarkers: store.state.map.routeOverlay == nil ? store.state.map.markers : [],
            logoBottomInset: 0,
            cameraBottomInset: mapCameraBottomInset,
            isInteractionEnabled: store.state.map.isMapInteractive,
            visibilityState: store.state.map.isMapInteractive ? .interactive : .covered,
            onEvent: { event in
                switch event {
                case .ready:
                    store.send(.map(.becameReady))

                case .markerTap(let markerID):
                    store.send(.map(.markerTapped(markerID)))

                case .routePointTap:
                    break

                case let .viewportChanged(center, zoomLevel, viewport, isUserInitiated):
                    store.send(.map(.viewportChanged(
                        center: center,
                        zoomLevel: zoomLevel,
                        viewport: viewport,
                        isUserInitiated: isUserInitiated
                    )))

                case .cameraMoveFinished(let requestID):
                    store.send(.map(.cameraMoveFinished(requestID)))

                case .failed:
                    break
                }
            }
        )
        .ignoresSafeArea()
    }

    private func mapControls() -> some View {
        ZStack {
            VStack(spacing: 16) {
                if store.state.map.mapLifecycle == .ready,
                   store.state.map.isHomeTabSelected {
                    HomeSearchEntryButton(
                        selectedSearchResultName: store.state.map.selectedSearchResultName,
                        action: { store.send(.map(.searchEntryTapped)) },
                        clearSelectedSearchResultAction: {
                            store.send(.map(.searchSelectionClearTapped))
                        }
                    )
                    .padding(.horizontal, 16)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }

                if store.state.map.isResearchButtonVisible,
                   store.state.map.isHomeTabSelected {
                    HomeResearchButton(
                        isLoading: store.state.bottomSheet.recommendList.isManualResearchLoading
                    ) {
                        store.send(.map(.recommendationResearchButtonTapped))
                    }

                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if shouldShowCurrentLocationButton {
                CurrentLocationButton(
                    isActive: store.state.map.isCurrentLocationButtonActive,
                    action: { store.send(.map(.currentLocationRequested)) }
                )
                .opacity(currentLocationButtonOpacity)
                .allowsHitTesting(currentLocationButtonOpacity > 0.95)
                .accessibilityHidden(currentLocationButtonOpacity <= 0.05)
                .padding(.trailing, 12)
                .padding(.bottom, currentLocationButtonBottomInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            if store.state.map.markerState == .failed {
                NetworkConnectionSnackbar(
                    refreshAction: { store.send(.map(.markerRetryRequested)) }
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mapCameraBottomInset: CGFloat {
        switch store.state.map.cameraFocus {
        case .closeSingleLocation, .courseMarker, .currentLocation:
            // 화면 상단 45% / 하단 55% 위치에 포커스 대상을 둔다.
            return screenHeight * 0.1

        case .normal, .koreaOverview, .region, .cluster:
            break
        }

        switch store.state.bottomSheet.route {
        case .recommendList:
            switch store.state.bottomSheet.recommendList.presentation {
            case .collapsed:
                return 0
            case .medium:
                return screenHeight * 0.5
            case .expanded:
                return screenHeight
            }

        case .filter, .parkingDetail:
            return screenHeight * 0.5

        case .courseDetail:
            return 0
        }
    }

    private var shouldShowCurrentLocationButton: Bool {
        guard store.state.map.mapLifecycle == .ready,
              store.state.map.isHomeTabSelected
        else {
            return false
        }

        guard !isFilterPresented else {
            return false
        }

        guard case .recommendList = store.state.bottomSheet.route else {
            return true
        }

        return store.state.bottomSheet.recommendList.presentation != .expanded
    }

    private var currentLocationButtonBottomInset: CGFloat {
        switch store.state.bottomSheet.route {
        case .recommendList:
            switch store.state.bottomSheet.recommendList.presentation {
            case .collapsed:
                return bottomTabBarAlignedControlInset
            case .medium:
                return sheetControlBottomInset(for: screenHeight * 0.5)
            case .expanded:
                return 0
            }

        case .filter, .parkingDetail:
            return sheetControlBottomInset(for: currentBottomSheetHeight)

        case .courseDetail:
            return sheetControlBottomInset(for: currentBottomSheetHeight)

        }
    }

    private var bottomTabBarAlignedControlInset: CGFloat {
        max(bottomTabBarHeight - screenSafeAreaInsets.bottom + 12, 0)
    }

    private func sheetControlBottomInset(for sheetHeight: CGFloat) -> CGFloat {
        max(sheetHeight + 12 - screenSafeAreaInsets.bottom, 0)
    }

    private var currentLocationButtonOpacity: CGFloat {
        let controlHeight: CGFloat = 40

        switch store.state.bottomSheet.route {
        case .recommendList:
            switch store.state.bottomSheet.recommendList.presentation {
            case .collapsed:
                return 1
            case .medium:
                let mediumHeight = screenHeight * 0.5
                let expansionOpacity = 1 - clamped(
                    (currentBottomSheetHeight - (mediumHeight + 12)) / controlHeight
                )
                let dismissalOpacity = 1 - clamped(
                    (mediumHeight - currentBottomSheetHeight) / controlHeight
                )
                return min(expansionOpacity, dismissalOpacity)
            case .expanded:
                return 0
            }

        case .filter, .parkingDetail:
            let restingHeight = currentLocationButtonRestingSheetHeight
            return 1 - clamped((restingHeight - currentBottomSheetHeight) / controlHeight)

        case .courseDetail:
            guard store.state.bottomSheet.courseDetail.presentation == .sheet else {
                return 0
            }
            let restingHeight = currentLocationButtonRestingSheetHeight
            let expansionOpacity = 1 - clamped(
                (currentBottomSheetHeight - (restingHeight + 12)) / controlHeight
            )
            let dismissalOpacity = 1 - clamped(
                (restingHeight - currentBottomSheetHeight) / controlHeight
            )
            return min(expansionOpacity, dismissalOpacity)

        }
    }

    private var currentLocationButtonRestingSheetHeight: CGFloat {
        switch store.state.bottomSheet.route {
        case .recommendList:
            switch store.state.bottomSheet.recommendList.presentation {
            case .collapsed:
                return 0
            case .medium:
                return screenHeight * 0.5
            case .expanded:
                return screenHeight
            }
        case .filter:
            return screenHeight * 0.5

        case .parkingDetail:
            return parkingBottomSheetHeight

        case .courseDetail:
            return store.state.bottomSheet.courseDetail.presentation == .sheet
                ? courseBottomSheetHeight
                : screenHeight
        }
    }

    private var currentBottomSheetHeight: CGFloat {
        transientBottomSheetHeight ?? currentLocationButtonRestingSheetHeight
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    private var locationSettingsAlertBinding: Binding<Bool> {
        Binding(
            get: { store.state.presentation.isLocationSettingsAlertPresented },
            set: { store.send(.presentation(.setLocationSettingsAlertPresented($0))) }
        )
    }

    private var searchPresentationBinding: Binding<Bool> {
        Binding(
            get: { store.state.presentation.isSearchPresented },
            set: { isPresented in
                if !isPresented {
                    store.send(.search(.dismissTapped))
                }
            }
        )
    }

    private var courseDetailExpandedPresentationBinding: Binding<Bool> {
        Binding(
            get: { isCourseDetailExpandedPresentation },
            set: { isPresented in
                guard !isPresented else { return }
                store.send(.bottomSheet(.courseDetail(.collapseRequested)))
            }
        )
    }

    private var courseDetailReviewPresentationBinding: Binding<Bool> {
        Binding(
            get: { presentation.courseDetailReviewPresentation.isPresented },
            set: { _ in }
        )
    }

    private func handleCourseDetailExpandedPresentationDismissed() {
        guard store.state.bottomSheet.courseDetail.presentation == .expandedDetail else { return }
        store.send(.bottomSheet(.courseDetail(.collapseRequested)))
    }

    private var isCourseDetailExpandedPresentation: Bool {
        store.state.bottomSheet.route == .courseDetail
            && store.state.bottomSheet.courseDetail.presentation == .expandedDetail
    }
}
