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

    @StateObject private var store: StoreOf<HomeReducer>
    @ObservedObject private var snackbarService: SnackbarService
    @State private var courseBottomSheetHeight: CGFloat = 180
    @State private var transientBottomSheetHeight: CGFloat?
    @State private var handledListPresentationRequestID = 0

    private let isHomeTabSelected: Bool
    private let onAuthenticationRequired: () -> Void
    private let onBottomTabBarVisibilityChanged: (Bool) -> Void
    private let listPresentationRequestID: Int
    private let pendingPlaceID: Int?
    private let onPendingPlaceHandled: () -> Void
    private let bottomTabBarHeight: CGFloat
    private let dependencies: AppDependencies

    init(
        isHomeTabSelected: Bool,
        onAuthenticationRequired: @escaping () -> Void = {},
        onBottomTabBarVisibilityChanged: @escaping (Bool) -> Void = { _ in },
        listPresentationRequestID: Int = 0,
        pendingPlaceID: Int? = nil,
        onPendingPlaceHandled: @escaping () -> Void = {},
        bottomTabBarHeight: CGFloat,
        dependencies: AppDependencies
    ) {
        self.isHomeTabSelected = isHomeTabSelected
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onBottomTabBarVisibilityChanged = onBottomTabBarVisibilityChanged
        self.listPresentationRequestID = listPresentationRequestID
        self.pendingPlaceID = pendingPlaceID
        self.onPendingPlaceHandled = onPendingPlaceHandled
        self.bottomTabBarHeight = bottomTabBarHeight
        self.dependencies = dependencies

        _snackbarService = ObservedObject(wrappedValue: dependencies.snackbarService)
        _store = StateObject(wrappedValue: Store(
            state: HomeReducer.State(),
            reducer: HomeReducer(
                dependencies: dependencies,
                authenticationRequired: onAuthenticationRequired
            )
        ))
    }

    var body: some View {
        core
            .onAppear {
                store.send(.map(.tabSelectionChanged(isHomeTabSelected)))
                store.send(.map(.activityChanged(scenePhase == .active)))
                onBottomTabBarVisibilityChanged(store.state.presentation.isBottomTabBarVisible)
                handleHomeNavigationRequest()
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
            // TODO: 스낵바 손보기(윤수)
            .rodiSnackbar(message: snackbarService.message)
            .onChange(of: store.state.presentation.pendingSnackbar) { snackbar in
                guard let snackbar else { return }
                snackbarService.show(snackbar)
                store.send(.presentation(.snackbarRequestHandled))
            }
            .onChange(of: store.state.presentation.isBottomTabBarVisible) {
                onBottomTabBarVisibilityChanged($0)
            }
            .fullScreenCover(isPresented: searchPresentationBinding) {
                if let origin = store.state.presentation.searchOrigin {
                    HomeSearchView(
                        origin: origin,
                        state: store.state.search,
                        send: { store.send(.search($0)) }
                    )
                }
            }
            .onChange(of: isHomeTabSelected) { isSelected in
                store.send(.map(.tabSelectionChanged(isSelected)))
            }
            .onChange(of: scenePhase) { phase in
                store.send(.map(.activityChanged(phase == .active)))
            }
            .onChange(of: listPresentationRequestID) { _ in
                handleHomeNavigationRequest()
            }
            .onChange(of: pendingPlaceID) { _ in
                handleHomeNavigationRequest()
            }
    }
}


// MARK: - Core
extension HomeView {

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
                    hasLocationPermission: store.state.map.locationState == .resolved,
                    bottomTabBarHeight: bottomTabBarHeight,
                    onCourseDetailHeightChanged: { height in
                        guard abs(courseBottomSheetHeight - height) > 0.5 else { return }
                        courseBottomSheetHeight = height
                    },
                    onVisibleHeightChanged: { height, isTransient in
                        transientBottomSheetHeight = isTransient ? height : nil
                    },
                    requestLocationPermission: {
                        store.send(.presentation(.setLocationSettingsAlertPresented(true)))
                    }
                )
            } else {
                initialMapLoadingView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleHomeNavigationRequest() {
        if listPresentationRequestID > handledListPresentationRequestID {
            handledListPresentationRequestID = listPresentationRequestID
            store.send(.bottomSheet(.showRecommendList))
            store.send(.bottomSheet(.recommendList(.present)))
        }

        guard let pendingPlaceID else { return }
        store.send(.bottomSheet(.resolvePlace(id: pendingPlaceID)))
        onPendingPlaceHandled()
    }
}


// MARK: - Layout
extension HomeView {

    private var screenHeight: CGFloat {
        screenBounds?.height ?? 0
    }

    private var isInitialMapPresentationReady: Bool {
        let map = store.state.map
        let hasResolvedInitialLocation = map.locationState == .resolved || map.locationState == .unavailable
        let hasRenderedMarkers = map.markerState == .failed
            || (map.markerState == .loaded && map.hasCompletedInitialMarkerRendering)

        return map.mapLifecycle == .ready
            && hasResolvedInitialLocation
            && hasRenderedMarkers
    }

    private var isFilterPresented: Bool {
        store.state.bottomSheet.route == .filter
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
                   store.state.map.isMapInteractive {
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
                   store.state.map.isMapInteractive {
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
                    isActive: store.state.map.locationState == .requesting,
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
                NetworkRetryBanner(
                    retryAction: { store.send(.map(.markerRetryRequested)) }
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mapCameraBottomInset: CGFloat {
        switch store.state.map.cameraFocus {
        case .closeSingleLocation, .currentLocation:
            // 화면 상단 45% / 하단 55% 위치에 포커스 대상을 둔다.
            return screenHeight * 0.1

        case .normal, .koreaOverview, .cluster:
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
              store.state.map.isMapInteractive
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

        case .filter, .parkingDetail, .courseDetail:
            let restingHeight = currentLocationButtonRestingSheetHeight
            return 1 - clamped((restingHeight - currentBottomSheetHeight) / controlHeight)

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
        case .filter, .parkingDetail:
            return screenHeight * 0.5
        case .courseDetail:
            return courseBottomSheetHeight
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
}
