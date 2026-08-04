//
//  HomeMapView.swift
//  Rodi
//

import Clarity
import SwiftUI

enum HomeMapOutput {
    case mapReady
    case markerSelected(RodiCourseItem)
    case viewportChanged(viewport: PlaceViewport, center: RodiCoordinate, isUserInitiated: Bool)
    case selectionInvalidated
    case initialPlaceListSearchPrepared(RodiCoordinate)
    case locationNotice(String)
    case locationSettingsRequested
    case researchRequested
    case searchRequested
    case searchSelectionCleared
}

struct HomeMapView<Overlay: View>: View {

    struct Configuration {
        let logoBottomInset: CGFloat
        let cameraBottomInset: CGFloat
        let isInteractionEnabled: Bool
        let visibilityState: RodiMapVisibilityState
        let isAccessibilityHidden: Bool
        let showsFloatingControl: Bool
        let floatingControlOpacity: CGFloat
        let allowsFloatingControlHitTesting: Bool
        let showsResearchButton: Bool
        let isResearchLoading: Bool
        let selectedSearchResultName: String?
    }

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var runtimeService = HomeMapRuntimeService()
    @State private var networkMonitor = HomeNetworkMonitor()
    @ObservedObject private var homeStore: StoreOf<HomeReducer>
    private let configuration: Configuration
    private let onOutput: (HomeMapOutput) -> Void
    private let overlay: () -> Overlay

    init(
        homeStore: StoreOf<HomeReducer>,
        configuration: Configuration,
        onOutput: @escaping (HomeMapOutput) -> Void,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.homeStore = homeStore
        self.configuration = configuration
        self.onOutput = onOutput
        self.overlay = overlay
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeMapLayer(
                homeStore: homeStore,
                logoBottomInset: configuration.logoBottomInset,
                cameraBottomInset: configuration.cameraBottomInset,
                isInteractionEnabled: configuration.isInteractionEnabled,
                visibilityState: configuration.visibilityState,
                isAccessibilityHidden: configuration.isAccessibilityHidden,
                onEvent: handleMapEvent
            )
            .clarityMask()

            HomeStatusLayer(
                homeStore: homeStore,
                retryAction: { homeStore.send(.map(.retryLoading)) }
            )

            if !configuration.isAccessibilityHidden {
                VStack(spacing: 8) {
                    HomeSearchEntryButton(
                        selectedSearchResultName: configuration.selectedSearchResultName,
                        action: { onOutput(.searchRequested) },
                        clearSelectedSearchResultAction: { onOutput(.searchSelectionCleared) }
                    )

                    if configuration.showsResearchButton {
                    HomeResearchButton(
                        isLoading: configuration.isResearchLoading,
                        action: { onOutput(.researchRequested) }
                    )

                    }

                    Spacer()
                }
                .padding(.top, 5)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(0.7)
            }

            if configuration.showsFloatingControl {
                HomeFloatingControlLayer(
                    isCurrentLocationActive: homeStore.state.map.isCurrentLocationButtonActive,
                    mapZoomLevel: homeStore.state.map.zoomLevel,
                    bottomInset: configuration.logoBottomInset,
                    opacity: configuration.floatingControlOpacity,
                    allowsHitTesting: configuration.allowsFloatingControlHitTesting,
                    isAccessibilityHidden: false,
                    spacing: 12,
                    currentLocationAction: requestCurrentLocation
                )
            }

            // Kakao 지도는 UIKit UIViewRepresentable이다. 지도 외부 ZStack의 형제 레이어는
            // iOS 26에서 지도 UIView 뒤로 합성될 수 있어, Home UI 오버레이를 같은 스택에서 렌더링한다.
            overlay()
                .zIndex(4)
        }
        .onAppear(perform: startServices)
        .onDisappear(perform: stopServices)
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            runtimeService.refreshLocationAuthorization()
        }
        .onChange(of: homeStore.state.map.currentLocationRequestID) { _ in
            runtimeService.requestCurrentLocationAfterStoreUpdate(
                minimumCameraRequestID: homeStore.state.map.cameraRequestID
            )
        }
        .onChange(of: homeStore.state.map.items.map(\.id)) { _ in
            runtimeService.refreshMapMarkers(for: homeStore.state.visibleItems)
        }
    }

    private func startServices() {
        runtimeService.start(onEvent: handleRuntimeEvent)
        runtimeService.showInitialPlaceMapIfNeeded()
        homeStore.send(.map(.loadItems))
        networkMonitor.start { isUnavailable in
            homeStore.send(.map(.setNetworkUnavailable(isUnavailable)))
        }
    }

    private func stopServices() {
        runtimeService.stop()
        networkMonitor.stop()
        homeStore.send(.map(.cancelItemsLoading))
    }

    private func handleMapEvent(_ event: RodiMapEvent) {
        switch event {
        case .ready:
            homeStore.send(.map(.ready))
            runtimeService.markMapReady()
            runtimeService.renderInitialMapMarkers(for: homeStore.state.visibleItems)
            onOutput(.mapReady)

        case .markerTap(let markerID):
            handleMarkerTap(markerID)

        case .viewportChanged(let center, let zoomLevel, let viewport, let isUserInitiated):
            homeStore.send(.map(.viewportChanged(
                center: center,
                zoomLevel: zoomLevel,
                viewport: viewport,
                isUserInitiated: isUserInitiated
            )))
            runtimeService.updateMapViewport(center: center, zoomLevel: zoomLevel)
            runtimeService.updateMapMarkersForViewportIfNeeded(for: homeStore.state.visibleItems)
            onOutput(.viewportChanged(viewport: viewport, center: center, isUserInitiated: isUserInitiated))

        case .cameraMoveFinished(let requestID):
            homeStore.send(.map(.cameraMoveFinished(requestID: requestID)))
            runtimeService.markCameraMoveFinished(requestID: requestID)

        case .failed(let message):
            homeStore.send(.map(.loadingFailed(message)))
            runtimeService.failMapLoading(message: message)
        }
    }

    private func handleMarkerTap(_ markerID: String) {
        if runtimeService.focusClusterMarker(markerID: markerID, visibleItems: homeStore.state.visibleItems) {
            return
        }

        guard let item = homeStore.state.visibleItems.first(where: { $0.mapMarker?.id == markerID }) else {
            return
        }

        onOutput(.markerSelected(item))
    }

    private func requestCurrentLocation() {
        onOutput(.selectionInvalidated)
        homeStore.send(.map(.requestCurrentLocation))
    }

    private func handleRuntimeEvent(_ event: HomeRuntimeEvent) {
        switch event {
        case .selectionInvalidated:
            onOutput(.selectionInvalidated)
        case .renderedMapMarkersChanged(let markers):
            homeStore.send(.map(.setVisibleMapMarkers(markers)))
        case .mapErrorMessageChanged(let message):
            homeStore.send(.map(.setErrorMessage(message)))
        case .mapLoadingChanged(let isLoading):
            homeStore.send(.map(.setLoading(isLoading)))
        case .shouldRenderMapChanged(let shouldRender):
            homeStore.send(.map(.setShouldRender(shouldRender)))
        case .cameraStateChanged(let target, let requestID, let animatedRequestID, let focus):
            homeStore.send(.map(.setCameraState(
                target: target,
                requestID: requestID,
                animatedRequestID: animatedRequestID,
                focus: focus
            )))
        case .userLocationCoordinateChanged(let coordinate):
            homeStore.send(.map(.setUserLocationCoordinate(coordinate)))
        case .userHeadingDegreesChanged(let degrees):
            homeStore.send(.map(.setUserHeadingDegrees(degrees)))
        case .locationPermissionChanged(let hasPermission):
            homeStore.send(.map(.setLocationPermission(hasPermission)))
        case .currentLocationButtonActiveChanged(let isActive):
            homeStore.send(.map(.setCurrentLocationButtonActive(isActive)))
        case .initialPlaceListSearchPrepared(let origin):
            onOutput(.initialPlaceListSearchPrepared(origin))
        case .locationNoticeRequested(let message):
            onOutput(.locationNotice(message))
        case .locationPermissionAlertRequested:
            onOutput(.locationSettingsRequested)
        }
    }
}
