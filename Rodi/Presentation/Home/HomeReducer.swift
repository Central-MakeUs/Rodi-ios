//
//  HomeReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct HomeReducer: Reducer {

    // MARK: State
    struct State {
        var map = MapState()
        var bottomSheet = HomeBottomSheetReducer.State()
        var search = HomeSearchReducer.State()
        var presentation = PresentationState()
    }

    struct MapState {
        // MARK: Map lifecycle
        var mapLifecycle: MapLifecycle = .inactive
        var isHomeTabSelected = false
        var isAppActive = true
        // TODO: 계산 프로퍼티(isMapInteractive) 없어야함(윤수)
        var isMapInteractive: Bool { isHomeTabSelected && isAppActive }

        // MARK: Map camera
        var cameraTarget = RodiCoordinate.southKoreaCenter
        var cameraRequestID = 0
        var animatedCameraRequestID: Int?
        var cameraFocus: RodiMapCameraFocus = .koreaOverview
        var mapZoomLevel = 6

        // MARK: User location
        var locationState: LocationState = .idle
        var userLocation: RodiCoordinate?
        var userHeadingDegrees: Double?

        // MARK: Map markers
        var markerState: MarkerState = .idle
        var mapItems: [RodiCourseItem] = []
        var markers: [RodiMapMarker] = []
        var markerRenderingGeneration = 0
        var hasCompletedInitialMarkerRendering = false
        var displayedMarkerTier: RodiHomeMarkerClusterIndex.Tier?
        var forcedMarkerTier: RodiHomeMarkerClusterIndex.Tier?
        var forcedMarkerTierZoomLevel: Int?
        var selectedMarkerID: String?
        var selectedSearchResultName: String?
        var isResearchButtonVisible = false

        // MARK: Route
        var routeOverlay: RodiRouteOverlay?
    }

    struct PresentationState {
        var pendingSnackbar: ToastStruct?
        var isLocationSettingsAlertPresented = false
        var isBottomTabBarVisible = true
        var isSearchPresented = false
        var searchOrigin: RodiCoordinate?
    }

    // MARK: Action
    enum Action {
        case map(MapAction)
        case bottomSheet(HomeBottomSheetReducer.Action)
        case search(HomeSearchReducer.Action)
        case presentation(PresentationAction)
    }

    enum MapAction {
        case tabSelectionChanged(Bool)
        case activityChanged(Bool)
        case becameReady
        case viewportChanged(
            center: RodiCoordinate,
            zoomLevel: Int,
            viewport: PlaceViewport,
            isUserInitiated: Bool
        )
        case markerTapped(String)
        case savedPlaceSelected(PlaceListItem)
        case cameraMoveFinished(Int)
        case currentLocationRequested
        case markerRetryRequested
        case recommendationResearchButtonTapped
        case searchEntryTapped
        case searchSelectionClearTapped
        case initialLocationRequested
        case initialMarkersLoadRequested
        case serviceOutput(MapServiceOutAction)
        case markerRenderBatchUpdated([RodiMapMarker], generation: Int)
        case initialMarkerRenderingFinished(generation: Int)
    }

    enum PresentationAction {
        case setLocationSettingsAlertPresented(Bool)
        case snackbarRequestHandled
    }

    /// NOTE - 확인 필요
    private let mapService: MapService
    private let markerRenderingService: MapMarkerRenderingService
    private let bottomSheetReducer: HomeBottomSheetReducer
    private let searchReducer: HomeSearchReducer
    private let hasActiveSession: () -> Bool
    /// NOTE - 확인 필요
    private let authenticationRequired: () -> Void
    private let markerTierResolver = MapMarkerTierResolver()
    private let markerInteractionResolver = MapMarkerInteractionResolver()

    private enum CancellationID: Hashable {
        case progressiveMarkerRendering
        case userHeadingUpdates
    }

    init(
        dependencies: AppDependencies,
        authenticationRequired: @escaping () -> Void = {}
    ) {
        mapService = MapService(
            placeRepository: dependencies.placeRepository,
            locationService: MapLocationService()
        )
        markerRenderingService = MapMarkerRenderingService()
        bottomSheetReducer = HomeBottomSheetReducer(dependencies: dependencies)
        searchReducer = HomeSearchReducer(
            placeRepository: dependencies.placeRepository,
            recentSearchRepository: dependencies.recentSearchRepository
        )
        hasActiveSession = {
            [dependencies.tokenStore.accessToken, dependencies.tokenStore.refreshToken]
                .contains { $0?.isEmpty == false }
        }
        self.authenticationRequired = authenticationRequired
    }
}


// MARK: - Reduce

extension HomeReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .map(let action):
            return reduceMap(&state, action: action)

        case .bottomSheet(let action):
            return reduceBottomSheet(&state, action: action)

        case .search(let action):
            return reduceSearch(&state, action: action)

        case .presentation(let action):
            return reducePresentation(&state, action: action)
        }
    }

    private func reduceMap(_ state: inout State, action: MapAction) -> Effect<Action> {
        var map = state.map
        defer { state.map = map }

        switch action {
        case .tabSelectionChanged(let isSelected):
            let wasMapInteractive = map.isMapInteractive
            map.isHomeTabSelected = isSelected
            return updateMapVisibility(wasMapInteractive: wasMapInteractive, state: &map)

        case .activityChanged(let isActive):
            let wasMapInteractive = map.isMapInteractive
            map.isAppActive = isActive
            return updateMapVisibility(wasMapInteractive: wasMapInteractive, state: &map)

        case .becameReady:
            guard map.mapLifecycle == .activating else { return .none }
            map.mapLifecycle = .ready
            return map.isMapInteractive ? initialMapDataLoadEffect() : .none

        case let .viewportChanged(center, zoomLevel, viewport, isUserInitiated):
            map.mapZoomLevel = zoomLevel
            let tierResolution = markerTierResolver.resolve(
                zoomLevel: zoomLevel,
                forcedTier: map.forcedMarkerTier,
                forcedTierZoomLevel: map.forcedMarkerTierZoomLevel
            )
            map.forcedMarkerTier = tierResolution.forcedTier
            map.forcedMarkerTierZoomLevel = tierResolution.forcedTierZoomLevel
            let tier = tierResolution.tier

            if map.markerState == .loaded,
               map.displayedMarkerTier != tier {
                map.displayedMarkerTier = tier
                if tier != .individual, isUserInitiated {
                    map.selectedMarkerID = nil
                }
                map.markers = RodiHomeMarkerClusterIndex.markers(
                    for: map.mapItems,
                    tier: tier,
                    selectedMarkerID: map.selectedMarkerID
                )
            }

            return .send(.bottomSheet(.recommendList(.viewportChanged(
                viewport: viewport,
                center: center,
                isUserInitiated: isUserInitiated
            ))))

        case .markerTapped(let markerID):
            guard let interaction = markerInteractionResolver.resolve(
                markerID: markerID,
                markers: map.markers,
                items: map.mapItems
            ) else {
                return .none
            }

            switch interaction {
            case .cluster(let marker, let target):
                map.selectedMarkerID = nil
                map.routeOverlay = nil
                map.markerRenderingGeneration += 1
                map.forcedMarkerTier = target.nextTier
                map.forcedMarkerTierZoomLevel = nil
                map.cameraTarget = marker.coordinate
                map.cameraFocus = .cluster(coordinates: target.coordinates)
                map.cameraRequestID += 1
                map.animatedCameraRequestID = map.cameraRequestID
                return .cancel(id: CancellationID.progressiveMarkerRendering)

            case .course(let marker, let placeID), .parking(let marker, let placeID):
                state.presentation.isBottomTabBarVisible = false
                map.routeOverlay = nil
                map.selectedMarkerID = markerID
                map.markerRenderingGeneration += 1
                map.cameraTarget = marker.coordinate
                map.cameraFocus = .closeSingleLocation
                map.cameraRequestID += 1
                map.animatedCameraRequestID = map.cameraRequestID
                map.markers = RodiHomeMarkerClusterIndex.markers(
                    for: map.mapItems,
                    tier: map.displayedMarkerTier
                        ?? RodiHomeMarkerClusterIndex.Tier(zoomLevel: map.mapZoomLevel),
                    selectedMarkerID: markerID
                )
                return .send(.bottomSheet(.resolvePlace(id: placeID)))
            }

        case .savedPlaceSelected(let place):
            let markerID = place.type == .course
                ? "course-\(place.id)"
                : "parking-\(place.id)"

            state.presentation.isBottomTabBarVisible = false
            map.routeOverlay = nil
            map.selectedSearchResultName = nil
            map.selectedMarkerID = markerID
            map.markerRenderingGeneration += 1
            map.forcedMarkerTier = .individual
            map.forcedMarkerTierZoomLevel = nil
            map.displayedMarkerTier = .individual
            map.cameraTarget = RodiCoordinate(latitude: place.latitude, longitude: place.longitude)
            map.cameraFocus = .closeSingleLocation
            map.cameraRequestID += 1
            map.animatedCameraRequestID = map.cameraRequestID
            map.markers = RodiHomeMarkerClusterIndex.markers(
                for: map.mapItems,
                tier: .individual,
                selectedMarkerID: map.selectedMarkerID
            )
            if map.markerState == .loaded {
                map.hasCompletedInitialMarkerRendering = true
            }
            return .run { send in
                await send(.bottomSheet(.resolveSavedPlace(place)))
            }
            .cancelTask(id: CancellationID.progressiveMarkerRendering)

        case .cameraMoveFinished(let requestID):
            guard map.animatedCameraRequestID == requestID else { return .none }
            map.animatedCameraRequestID = nil
            return .none

        case .currentLocationRequested:
            guard map.mapLifecycle == .ready,
                  map.locationState != .requesting
            else {
                return .none
            }
            return .send(.bottomSheet(.prepareForCurrentLocation))

        case .recommendationResearchButtonTapped:
            map.routeOverlay = nil
            map.selectedMarkerID = nil
            map.selectedSearchResultName = nil
            map.markers = RodiHomeMarkerClusterIndex.markers(
                for: map.mapItems,
                tier: map.displayedMarkerTier
                    ?? RodiHomeMarkerClusterIndex.Tier(zoomLevel: map.mapZoomLevel)
            )

            let origin = map.userLocation
            return .send(.bottomSheet(.recommendList(.reloadCurrentViewport(origin: origin))))

        case .searchEntryTapped:
            guard hasActiveSession() else {
                authenticationRequired()
                return .none
            }
            state.search = .init()
            state.presentation.searchOrigin = map.cameraTarget
            state.presentation.isSearchPresented = true
            return .none

        case .searchSelectionClearTapped:
            state.search = .init()
            map.selectedSearchResultName = nil
            map.routeOverlay = nil
            map.selectedMarkerID = nil
            map.isResearchButtonVisible = false
            map.markers = RodiHomeMarkerClusterIndex.markers(
                for: map.mapItems,
                tier: map.displayedMarkerTier
                    ?? RodiHomeMarkerClusterIndex.Tier(zoomLevel: map.mapZoomLevel)
            )
            state.presentation.isBottomTabBarVisible = true
            return .send(.bottomSheet(.clearSearchSelection))

        case .markerRetryRequested:
            guard map.markerState == .failed else { return .none }
            map.hasCompletedInitialMarkerRendering = false
            map.markerState = .loading
            return mapServiceEffect(.loadPlaceCoordinates)

        case .initialLocationRequested:
            guard map.mapLifecycle == .ready,
                  map.locationState == .idle
            else {
                return .none
            }
            map.locationState = .requesting
            return mapServiceEffect(.requestCurrentLocation(source: .initial))

        case .initialMarkersLoadRequested:
            guard map.mapLifecycle == .ready,
                  map.markerState == .idle
            else {
                return .none
            }
            map.hasCompletedInitialMarkerRendering = false
            map.markerState = .loading
            return mapServiceEffect(.loadPlaceCoordinates)

        case .serviceOutput(let output):
            return reduceMapServiceOutput(
                output,
                map: &map,
                presentation: &state.presentation
            )

        case .markerRenderBatchUpdated(let markers, let generation):
            guard map.markerState == .loaded,
                  map.markerRenderingGeneration == generation
            else {
                return .none
            }
            map.markers = markers.map { marker in
                RodiMapMarker(
                    id: marker.id,
                    kind: marker.kind,
                    title: marker.title,
                    coordinate: marker.coordinate,
                    isSelected: marker.id == map.selectedMarkerID
                )
            }
            return .none

        case .initialMarkerRenderingFinished(let generation):
            guard map.markerState == .loaded,
                  map.markerRenderingGeneration == generation
            else {
                return .none
            }
            map.hasCompletedInitialMarkerRendering = true
            return .none
        }
    }

    private func reduceBottomSheet(
        _ state: inout State, action: HomeBottomSheetReducer.Action) -> Effect<Action> {
    guard case .delegate(let delegate) = action else {
        return bottomSheetReducer
            .reduce(&state.bottomSheet, with: action)
            .map(Action.bottomSheet)
    }

    switch delegate {
    case .mapPlaceResolved(let detail):
        state.presentation.isBottomTabBarVisible = false
        focusMap(on: detail, state: &state.map)

    case .mapRouteOverlayChanged(let overlay):
        state.map.routeOverlay = overlay

    case .mapFocusRequested(let coordinate):
        state.map.cameraTarget = coordinate
        state.map.cameraFocus = .closeSingleLocation
        state.map.cameraRequestID += 1
        state.map.animatedCameraRequestID = state.map.cameraRequestID

    case .mapDetailDismissed:
        state.map.routeOverlay = nil
        state.map.selectedMarkerID = nil
        state.map.selectedSearchResultName = nil
        state.map.isResearchButtonVisible = false
        state.map.markers = RodiHomeMarkerClusterIndex.markers(
            for: state.map.mapItems,
            tier: state.map.displayedMarkerTier
                ?? RodiHomeMarkerClusterIndex.Tier(zoomLevel: state.map.mapZoomLevel)
        )
        state.presentation.isBottomTabBarVisible = true

    case .currentLocationReady:
        guard state.map.mapLifecycle == .ready,
              state.map.locationState != .requesting
        else {
            return .none
        }
        state.map.locationState = .requesting
        return mapServiceEffect(.requestCurrentLocation(source: .userInitiated))

    case let .recommendationPresentationChanged(isBottomTabBarVisible, isResearchButtonVisible):
        state.presentation.isBottomTabBarVisible = isBottomTabBarVisible
        state.map.isResearchButtonVisible = isResearchButtonVisible

    case .requestAuthentication:
        authenticationRequired()

    case .showSnackbar(let message):
        state.presentation.pendingSnackbar = ToastStruct(message: message, state: .error)
    }

    return .none
}

    private func reduceSearch(
        _ state: inout State, action: HomeSearchReducer.Action) -> Effect<Action> {
        guard case .delegate(let delegate) = action else {
            return searchReducer
                .reduce(&state.search, with: action)
                .map(Action.search)
        }

        switch delegate {
        case let .placeSelected(id, name):
            state.presentation.isSearchPresented = false
            state.presentation.searchOrigin = nil
            state.search = .init()
            state.map.selectedSearchResultName = name
            state.map.routeOverlay = nil
            state.map.selectedMarkerID = nil
            state.map.isResearchButtonVisible = false
            state.map.markers = RodiHomeMarkerClusterIndex.markers(
                for: state.map.mapItems,
                tier: state.map.displayedMarkerTier
                    ?? RodiHomeMarkerClusterIndex.Tier(zoomLevel: state.map.mapZoomLevel)
            )
            return .send(.bottomSheet(.resolvePlace(id: id)))

        case .dismissed:
            state.presentation.isSearchPresented = false
            state.presentation.searchOrigin = nil

        case .showSnackbar(let message):
            state.presentation.pendingSnackbar = ToastStruct(message: message, state: .error)
        }

        return .none
    }

    private func reducePresentation(
        _ state: inout State, action: PresentationAction) -> Effect<Action> {
        switch action {
        case .setLocationSettingsAlertPresented(let isPresented):
            state.presentation.isLocationSettingsAlertPresented = isPresented

        case .snackbarRequestHandled:
            state.presentation.pendingSnackbar = nil
        }
        return .none
    }

    private func reduceMapServiceOutput(
        _ output: MapServiceOutAction, map: inout MapState, presentation: inout PresentationState
    ) -> Effect<Action> {
        switch output {
        case .currentLocationResolved(let coordinate):
            guard map.locationState == .requesting else { return .none }
            map.locationState = .resolved
            map.userLocation = coordinate
            map.cameraTarget = coordinate
            map.cameraFocus = .currentLocation
            map.cameraRequestID += 1
            map.animatedCameraRequestID = nil
            return userHeadingUpdatesEffect(origin: coordinate)

        case .currentLocationUnavailable(let source):
            guard map.locationState == .requesting else { return .none }
            map.locationState = .unavailable
            if source == .userInitiated {
                presentation.pendingSnackbar = ToastStruct(
                    message: "현재 위치를 확인할 수 없어요. 다시 시도해주세요.",
                    state: .error
                )
            }
            return .none

        case .currentLocationPermissionDenied(let source):
            guard map.locationState == .requesting else { return .none }
            map.locationState = .unavailable
            if source == .userInitiated {
                resetToKoreaOverview(&map)
                presentation.isLocationSettingsAlertPresented = true
            }
            return .none

        case .placeCoordinatesLoaded(let coordinates):
            guard map.markerState == .loading else { return .none }
            map.markerState = .loaded
            map.mapItems = coordinates.map(RodiCourseItem.init(placeCoordinate:))
            map.markerRenderingGeneration += 1

            let tierResolution = markerTierResolver.resolve(
                zoomLevel: map.mapZoomLevel,
                forcedTier: map.forcedMarkerTier,
                forcedTierZoomLevel: map.forcedMarkerTierZoomLevel
            )
            map.forcedMarkerTier = tierResolution.forcedTier
            map.forcedMarkerTierZoomLevel = tierResolution.forcedTierZoomLevel
            map.displayedMarkerTier = tierResolution.tier

            return markerRenderingEffect(
                RodiHomeMarkerClusterIndex.markers(
                    for: map.mapItems,
                    tier: tierResolution.tier,
                    selectedMarkerID: map.selectedMarkerID
                ),
                generation: map.markerRenderingGeneration,
                reportsInitialCompletion: true
            )

        case .placeCoordinatesLoadFailed:
            guard map.markerState == .loading else { return .none }
            map.markerState = .failed
            return .none

        case .userHeadingUpdated(let degrees):
            map.userHeadingDegrees = degrees
            return .none
        }
    }
}


// MARK: - Effect

extension HomeReducer {

    private func updateMapVisibility(
        wasMapInteractive: Bool, state: inout MapState) -> Effect<Action> {
        guard wasMapInteractive != state.isMapInteractive else { return .none }

        guard state.isMapInteractive else {
            state.markerRenderingGeneration += 1
            return .cancel(id: CancellationID.progressiveMarkerRendering)
        }

        switch state.mapLifecycle {
        case .inactive:
            state.mapLifecycle = .activating
            return .none

        case .activating:
            return .none

        case .ready:
            if state.markerState == .idle {
                return initialMapDataLoadEffect()
            }

            if state.markerState == .loaded,
               let tier = state.displayedMarkerTier {
                state.markers = RodiHomeMarkerClusterIndex.markers(
                    for: state.mapItems,
                    tier: tier,
                    selectedMarkerID: state.selectedMarkerID
                )
                state.hasCompletedInitialMarkerRendering = true
            }
            return .none
        }
    }

    private func focusMap(on detail: PlaceDetail, state: inout MapState) {
        state.cameraTarget = RodiCoordinate(latitude: detail.latitude, longitude: detail.longitude)
        state.cameraFocus = .closeSingleLocation
        state.cameraRequestID += 1
        state.animatedCameraRequestID = state.cameraRequestID
    }

    private func resetToKoreaOverview(_ state: inout MapState) {
        state.userLocation = nil
        state.cameraTarget = .southKoreaCenter
        state.cameraFocus = .koreaOverview
        state.cameraRequestID += 1
        state.animatedCameraRequestID = nil
    }

    private func initialMapDataLoadEffect() -> Effect<Action> {
        .run { send in
            await send(.map(.initialLocationRequested))
            await send(.map(.initialMarkersLoadRequested))
        }
    }

    private func mapServiceEffect(_ input: MapServiceInAction) -> Effect<Action> {
        let mapService = mapService
        return .run { send in
            guard let output = await mapService.perform(input) else { return }
            await send(.map(.serviceOutput(output)))
        }
    }

    private func userHeadingUpdatesEffect(origin: RodiCoordinate) -> Effect<Action> {
        let mapService = mapService
        return .run { send in
            await send(.bottomSheet(.recommendList(.prepareInitialSearch(origin: origin))))

            let updates = await mapService.userHeadingUpdates()
            for await degrees in updates {
                guard !Task.isCancelled else { return }
                await send(.map(.serviceOutput(.userHeadingUpdated(degrees))))
            }
        }
        .cancelTask(id: CancellationID.userHeadingUpdates)
    }

    private func markerRenderingEffect(
        _ markers: [RodiMapMarker],
        generation: Int,
        reportsInitialCompletion: Bool = false
    ) -> Effect<Action> {
        let snapshots = markerRenderingService.progressiveSnapshots(for: markers)
        return .run { send in
            for await snapshot in snapshots {
                guard !Task.isCancelled else { return }
                await send(.map(.markerRenderBatchUpdated(snapshot, generation: generation)))
            }

            guard reportsInitialCompletion, !Task.isCancelled else { return }

            do {
                try await Task.sleep(nanoseconds: 120_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            await send(.map(.initialMarkerRenderingFinished(generation: generation)))
        }
        .cancelTask(id: CancellationID.progressiveMarkerRendering)
    }
}
