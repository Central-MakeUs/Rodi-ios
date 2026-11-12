//
//  HomeMapReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct HomeMapReducer: Reducer {
    typealias State = HomeMapState

    struct Dependencies {
        let placeRepository: PlaceRepository
        let hasActiveSession: () -> Bool
    }

    enum Action {
        case tabSelectionChanged(Bool)
        case activityChanged(Bool)
        case locationAuthorizationRefreshRequested
        case becameReady
        case viewportChanged(center: RodiCoordinate, zoomLevel: Int, viewport: PlaceViewport, isUserInitiated: Bool)
        case markerTapped(String)
        case savedPlaceSelected(PlaceListItem)
        case cameraMoveFinished(Int)
        case currentLocationRequested
        case markerRetryRequested
        case recommendationResearchButtonTapped
        case searchEntryTapped
        case searchSelectionClearTapped
        case initialLocationRequested
        case clusterQueryRequested(PlaceClusterQuery, listRevision: Int)
        case periodicLocationRefreshSchedulingRequested
        case periodicLocationRefreshTimerFired
        case serviceOutput(MapServiceOutAction)
        case markerRenderBatchUpdated([RodiMapMarker], generation: Int)
        case initialMarkerRenderingFinished(generation: Int)
        case placeResolved(PlaceDetail)
        case searchPlaceSelected(String)
        case regionSelected(name: String, center: RodiCoordinate)
        case routeOverlayChanged(RodiRouteOverlay?)
        case focusRequested(RodiCoordinate)
        case detailDismissed
        case currentLocationReady
        case researchButtonVisibilityChanged(Bool)
        case recommendationCollapsed
        case delegate(Delegate)
    }

    enum Delegate {
        case requestAuthentication
        case showLocationSettingsAlert(Bool)
        case showSnackbar(String)
        case bottomTabBarVisibilityChanged(Bool)
        case searchEntryRequested(origin: RodiCoordinate)
        case searchSelectionClearRequested
        case resolvePlace(Int)
        case resolveSavedPlace(PlaceListItem)
        case prepareForCurrentLocation
        case reloadCurrentViewport(origin: RodiCoordinate?)
        case viewportChanged(PlaceViewport, center: RodiCoordinate, isUserInitiated: Bool)
        case reloadAfterRegionViewport(viewport: PlaceViewport, origin: RodiCoordinate)
        case presentRecommendListForRegion(origin: RodiCoordinate)
        case prepareInitialSearch(origin: RodiCoordinate)
    }

    private enum CancellationID: Hashable {
        case progressiveMarkerRendering
        case clusterLoading
        case userHeadingUpdates
        case periodicLocationRefresh
    }

    private static let periodicLocationRefreshNanoseconds: UInt64 = 60_000_000_000
    private static let prolongedLocationUnavailableInterval: TimeInterval = 60

    private let mapService: MapService
    private let markerRenderingService = MapMarkerRenderingService()
    private let hasActiveSession: () -> Bool

    init(dependencies: Dependencies) {
        mapService = MapService(
            placeRepository: dependencies.placeRepository,
            locationService: MapLocationService()
        )
        hasActiveSession = dependencies.hasActiveSession
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .tabSelectionChanged(let isSelected):
            let wasInteractive = state.isMapInteractive
            state.isHomeTabSelected = isSelected
            if !isSelected { state.isCurrentLocationButtonActive = false }
            return updateVisibility(wasInteractive: wasInteractive, state: &state)

        case .activityChanged(let isActive):
            let wasInteractive = state.isMapInteractive
            state.isAppActive = isActive
            if !isActive { state.isCurrentLocationButtonActive = false }
            return updateVisibility(wasInteractive: wasInteractive, state: &state)

        case .locationAuthorizationRefreshRequested:
            let authorization = mapService.locationAuthorizationState
            state.locationAuthorizationState = authorization
            switch authorization {
            case .authorized:
                guard state.mapLifecycle == .ready, state.locationState != .requesting else {
                    return state.isMapInteractive ? .send(.periodicLocationRefreshSchedulingRequested) : .none
                }
                guard state.userLocation == nil else {
                    return state.isMapInteractive ? .send(.periodicLocationRefreshSchedulingRequested) : .none
                }
                state.locationState = .requesting
                let source: LocationRequestSource = state.hasCompletedInitialLocationResolution ? .foregroundRefresh : .initial
                return authorizationRefreshEffect(source: source)
            case .denied, .restricted:
                state.locationState = .unavailable
                state.hasCompletedInitialLocationResolution = true
                state.userLocation = nil
                state.userHeadingDegrees = nil
                return .cancel(id: CancellationID.userHeadingUpdates)
            case .notDetermined:
                if state.userLocation == nil, state.locationState == .unavailable { state.locationState = .idle }
                return .none
            }

        case .becameReady:
            guard state.mapLifecycle == .activating else { return .none }
            state.mapLifecycle = .ready
            return state.isMapInteractive ? initialMapDataLoadEffect() : .none

        case let .viewportChanged(center, _, viewport, isUserInitiated):
            if isUserInitiated { state.isCurrentLocationButtonActive = false }
            if viewport.longitudeSpan.isFinite, viewport.longitudeSpan > 0 {
                state.visibleLongitudeSpan = viewport.longitudeSpan
            }
            if let span = state.visibleLongitudeSpan,
               let level = state.clusterResult?.levelIndex(for: span),
               state.displayedClusterLevel != level {
                state.displayedClusterLevel = level
                state.markerRenderingGeneration += 1
                rebuildMarkers(&state)
                state.hasCompletedInitialMarkerRendering = true
            }
            var delegates: [Action] = [.delegate(.viewportChanged(viewport, center: center, isUserInitiated: isUserInitiated))]
            if !isUserInitiated, viewport.isValidForPlaceQuery,
               state.pendingRegionCameraRequestID == state.cameraRequestID,
               let origin = state.pendingRegionViewportReloadOrigin {
                state.pendingRegionCameraRequestID = nil
                state.pendingRegionViewportReloadOrigin = nil
                delegates.append(.delegate(.reloadAfterRegionViewport(viewport: viewport, origin: origin)))
            }
            return actions(delegates)

        case .markerTapped(let markerID):
            guard let marker = state.markers.first(where: { $0.id == markerID }) else { return .none }
            switch marker.kind {
            case .cluster:
                guard let bounds = state.clusterBoundsByMarkerID[markerID] else { return .none }
                state.isCurrentLocationButtonActive = false
                state.selectedMarkerID = nil
                state.routeOverlay = nil
                state.markerRenderingGeneration += 1
                rebuildMarkers(&state)
                state.hasCompletedInitialMarkerRendering = true
                state.cameraTarget = marker.coordinate
                state.cameraFocus = .cluster(coordinates: [
                    .init(latitude: bounds.southWestLatitude, longitude: bounds.southWestLongitude),
                    .init(latitude: bounds.northEastLatitude, longitude: bounds.northEastLongitude)
                ])
                requestCamera(&state)
                return .cancel(id: CancellationID.progressiveMarkerRendering)
            case .course, .parking:
                guard let placeID = Int(markerID.split(separator: "-").last ?? "") else { return .none }
                guard hasActiveSession() else {
                    return .send(.delegate(.requestAuthentication))
                }
                state.isCurrentLocationButtonActive = false
                state.routeOverlay = nil
                state.selectedSearchResultName = marker.title
                state.selectedMarkerID = markerID
                state.markerRenderingGeneration += 1
                state.cameraTarget = marker.coordinate
                state.cameraFocus = marker.kind == .course ? .courseMarker : .closeSingleLocation
                requestCamera(&state)
                rebuildMarkers(&state)
                state.hasCompletedInitialMarkerRendering = true
                return actions([.delegate(.bottomTabBarVisibilityChanged(false)), .delegate(.resolvePlace(placeID))])
            }

        case .savedPlaceSelected(let place):
            state.isCurrentLocationButtonActive = false
            state.routeOverlay = nil
            state.selectedSearchResultName = place.name
            selectMarker(id: markerID(for: place.type, id: place.id), coordinate: .init(latitude: place.latitude, longitude: place.longitude), focus: .closeSingleLocation, state: &state)
            return effects([.delegate(.bottomTabBarVisibilityChanged(false)), .delegate(.resolveSavedPlace(place))], cancellation: .progressiveMarkerRendering)

        case .cameraMoveFinished(let requestID):
            guard state.animatedCameraRequestID == requestID else { return .none }
            state.animatedCameraRequestID = nil
            return .none

        case .currentLocationRequested:
            guard state.mapLifecycle == .ready, state.locationState != .requesting else { return .none }
            state.isCurrentLocationButtonActive = true
            return .send(.delegate(.prepareForCurrentLocation))

        case .recommendationResearchButtonTapped:
            state.routeOverlay = nil
            state.selectedMarkerID = nil
            state.selectedSearchResultName = nil
            rebuildMarkers(&state)
            return .send(.delegate(.reloadCurrentViewport(origin: state.userLocation)))

        case .searchEntryTapped:
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            state.isCurrentLocationButtonActive = false
            return .send(.delegate(.searchEntryRequested(origin: state.cameraTarget)))

        case .searchSelectionClearTapped:
            clearSelection(&state)
            return actions([.delegate(.bottomTabBarVisibilityChanged(true)), .delegate(.searchSelectionClearRequested)])

        case .markerRetryRequested:
            guard state.markerState == .failed, let query = state.clusterQuery else { return .none }
            return loadClusters(query, state: &state)

        case .initialLocationRequested:
            guard state.mapLifecycle == .ready, state.locationState == .idle else { return .none }
            state.locationAuthorizationState = mapService.locationAuthorizationState
            state.locationState = .requesting
            return mapServiceEffect(.requestCurrentLocation(source: .initial))

        case let .clusterQueryRequested(query, listRevision):
            state.clusterListRevision = listRevision
            return loadClusters(query, state: &state)

        case .periodicLocationRefreshSchedulingRequested:
            guard state.isMapInteractive, state.mapLifecycle == .ready, state.locationAuthorizationState == .authorized, state.locationState != .requesting else {
                return .cancel(id: CancellationID.periodicLocationRefresh)
            }
            return periodicLocationRefreshEffect()

        case .periodicLocationRefreshTimerFired:
            guard state.isMapInteractive, state.mapLifecycle == .ready, mapService.locationAuthorizationState == .authorized, state.locationState != .requesting else { return .none }
            state.locationAuthorizationState = .authorized
            state.locationState = .requesting
            return mapServiceEffect(.requestCurrentLocation(source: .periodicRefresh))

        case .serviceOutput(let output):
            return reduceServiceOutput(output, state: &state)

        case .markerRenderBatchUpdated(let markers, let generation):
            guard state.markerState == .loaded, state.markerRenderingGeneration == generation else { return .none }
            state.markers = markers.map { .init(id: $0.id, kind: $0.kind, title: $0.title, coordinate: $0.coordinate, isSelected: $0.id == state.selectedMarkerID) }
            return .none

        case .initialMarkerRenderingFinished(let generation):
            guard state.markerState == .loaded, state.markerRenderingGeneration == generation else { return .none }
            state.hasCompletedInitialMarkerRendering = true
            return .none

        case .placeResolved(let detail):
            selectMarker(id: markerID(for: detail.type, id: detail.id), coordinate: .init(latitude: detail.latitude, longitude: detail.longitude), focus: .closeSingleLocation, state: &state)
            return .send(.delegate(.bottomTabBarVisibilityChanged(false)))

        case .searchPlaceSelected(let name):
            state.selectedSearchResultName = name
            state.routeOverlay = nil
            state.isListResearchButtonVisible = false
            rebuildMarkers(&state)
            return .none

        case let .regionSelected(name, center):
            state.selectedSearchResultName = name
            state.routeOverlay = nil
            state.selectedMarkerID = nil
            state.isListResearchButtonVisible = false
            state.didClusterRefreshFail = false
            state.clusterRequestRevision += 1
            rebuildMarkers(&state)
            state.cameraTarget = center
            state.cameraFocus = .region
            requestCamera(&state)
            state.pendingRegionViewportReloadOrigin = center
            state.pendingRegionCameraRequestID = state.cameraRequestID
            return .send(.delegate(.presentRecommendListForRegion(origin: center)))

        case .routeOverlayChanged(let overlay):
            state.routeOverlay = overlay
            return .none

        case .focusRequested(let coordinate):
            state.cameraTarget = coordinate
            state.cameraFocus = .closeSingleLocation
            requestCamera(&state)
            return .none

        case .detailDismissed:
            clearSelection(&state)
            return .send(.delegate(.bottomTabBarVisibilityChanged(true)))

        case .currentLocationReady:
            guard state.mapLifecycle == .ready, state.locationState != .requesting else { return .none }
            state.locationState = .requesting
            return mapServiceEffect(.requestCurrentLocation(source: .userInitiated))

        case .researchButtonVisibilityChanged(let visible):
            state.isListResearchButtonVisible = visible
            return .none

        case .recommendationCollapsed:
            state.selectedSearchResultName = nil
            return .none

        case .delegate:
            return .none
        }
    }
}

private extension HomeMapReducer {
    func reduceServiceOutput(_ output: MapServiceOutAction, state: inout State) -> Effect<Action> {
        switch output {
        case let .currentLocationResolved(coordinate, source):
            guard state.locationState == .requesting else { return .none }
            state.locationAuthorizationState = .authorized
            state.locationState = .resolved
            state.hasCompletedInitialLocationResolution = true
            state.userLocation = coordinate
            state.lastLocationResolvedAt = Date()
            state.hasShownProlongedLocationUnavailableNotice = false
            if source != .foregroundRefresh, source != .periodicRefresh {
                state.cameraTarget = coordinate
                state.cameraFocus = .currentLocation
                state.cameraRequestID += 1
                state.animatedCameraRequestID = nil
            }
            if source == .periodicRefresh { return .send(.periodicLocationRefreshSchedulingRequested) }
            return userHeadingUpdatesEffect(origin: coordinate)

        case .currentLocationUnavailable(let source):
            guard state.locationState == .requesting else { return .none }
            state.locationAuthorizationState = mapService.locationAuthorizationState
            state.locationState = .unavailable
            state.hasCompletedInitialLocationResolution = true
            var followUp: [Action] = []
            if source == .userInitiated {
                followUp.append(.delegate(.showSnackbar("현재 위치를 확인할 수 없어요. 다시 시도해주세요.")))
            } else if source == .periodicRefresh, shouldShowProlongedUnavailableNotice(for: state) {
                state.hasShownProlongedLocationUnavailableNotice = true
                followUp.append(.delegate(.showSnackbar("현재 위치를 확인할 수 없어요. 위치 신호가 안정되면 다시 갱신할게요.")))
            }
            if state.isMapInteractive, state.locationAuthorizationState == .authorized { followUp.append(.periodicLocationRefreshSchedulingRequested) }
            return actions(followUp)

        case let .currentLocationPermissionDenied(source, authorizationState):
            guard state.locationState == .requesting else { return .none }
            state.locationAuthorizationState = authorizationState
            state.locationState = .unavailable
            state.hasCompletedInitialLocationResolution = true
            state.userLocation = nil
            state.userHeadingDegrees = nil
            guard source == .userInitiated else { return .none }
            resetToKoreaOverview(&state)
            return .send(.delegate(.showLocationSettingsAlert(true)))

        case let .clustersLoaded(result, revision):
            guard revision == state.clusterRequestRevision else { return .none }
            guard let span = state.visibleLongitudeSpan ?? state.clusterQuery?.viewport.longitudeSpan,
                  let level = result.levelIndex(for: span) else {
                return reduceServiceOutput(.clusterLoadFailed(revision: revision), state: &state)
            }
            let isFirstResult = state.clusterResult == nil
            state.markerState = .loaded
            state.clusterResult = result
            state.displayedClusterLevel = level
            state.didClusterRefreshFail = false
            state.markerRenderingGeneration += 1
            let markers = serverMarkers(&state)
            if isFirstResult, state.isMapInteractive {
                return markerRenderingEffect(markers, generation: state.markerRenderingGeneration, reportsInitialCompletion: true)
            }
            state.markers = markers
            state.hasCompletedInitialMarkerRendering = true
            return .none

        case .clusterLoadFailed(let revision):
            guard revision == state.clusterRequestRevision else { return .none }
            if state.clusterResult == nil {
                state.markerState = .failed
            } else {
                state.didClusterRefreshFail = true
            }
            return .none

        case .userHeadingUpdated(let degrees):
            state.userHeadingDegrees = degrees
            return .none
        }
    }

    func updateVisibility(wasInteractive: Bool, state: inout State) -> Effect<Action> {
        guard wasInteractive != state.isMapInteractive else { return .none }
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
            if state.markerState == .idle { return initialMapDataLoadEffect() }
            if state.markerState == .loaded {
                rebuildMarkers(&state)
                state.hasCompletedInitialMarkerRendering = true
            }
            return .send(.periodicLocationRefreshSchedulingRequested)
        }
    }

    func clearSelection(_ state: inout State) {
        state.selectedSearchResultName = nil
        state.routeOverlay = nil
        state.selectedMarkerID = nil
        state.isListResearchButtonVisible = false
        rebuildMarkers(&state)
    }

    func selectMarker(id: String, coordinate: RodiCoordinate, focus: RodiMapCameraFocus, state: inout State) {
        guard state.selectedMarkerID != id else { return }
        state.selectedMarkerID = id
        state.markerRenderingGeneration += 1
        rebuildMarkers(&state)
        if state.markerState == .loaded { state.hasCompletedInitialMarkerRendering = true }
        state.cameraTarget = coordinate
        state.cameraFocus = focus
        requestCamera(&state)
    }

    func rebuildMarkers(_ state: inout State) {
        state.markers = serverMarkers(&state)
    }

    func serverMarkers(_ state: inout State) -> [RodiMapMarker] {
        guard let result = state.clusterResult, let index = state.displayedClusterLevel else { return [] }
        let level = result.levels[index]
        let individualIDs = Set(level.placeIDs)
        let selectedID = state.selectedMarkerID
        state.clusterBoundsByMarkerID = [:]
        let clusters = level.clusters.enumerated().map { offset, cluster in
            let id = "server-cluster-\(index)-\(offset)"
            state.clusterBoundsByMarkerID[id] = cluster.bounds
            return RodiMapMarker(id: id, kind: .cluster, title: String(cluster.count),
                                 coordinate: .init(latitude: cluster.latitude, longitude: cluster.longitude))
        }
        let places = result.places.compactMap { place -> RodiMapMarker? in
            guard individualIDs.contains(place.id) else { return nil }
            let id = markerID(for: place.type, id: place.id)
            return .init(id: id, kind: place.type == .course ? .course : .parking, title: place.name,
                         coordinate: .init(latitude: place.latitude, longitude: place.longitude),
                         isSelected: selectedID == id)
        }
        return clusters + places
    }

    func loadClusters(_ query: PlaceClusterQuery, state: inout State) -> Effect<Action> {
        guard query.viewport.isValidForPlaceQuery else { return .none }
        state.clusterQuery = query
        state.clusterRequestRevision += 1
        state.didClusterRefreshFail = false
        if state.clusterResult == nil { state.markerState = .loading }
        return mapServiceEffect(.loadClusters(query, revision: state.clusterRequestRevision))
            .cancelTask(id: CancellationID.clusterLoading)
    }

    func requestCamera(_ state: inout State) {
        state.cameraRequestID += 1
        state.animatedCameraRequestID = state.cameraRequestID
    }

    func markerID(for type: PlaceType, id: Int) -> String {
        type == .course ? "course-\(id)" : "parking-\(id)"
    }

    func resetToKoreaOverview(_ state: inout State) {
        state.userLocation = nil
        state.cameraTarget = .southKoreaCenter
        state.cameraFocus = .koreaOverview
        state.cameraRequestID += 1
        state.animatedCameraRequestID = nil
    }

    func shouldShowProlongedUnavailableNotice(for state: State) -> Bool {
        guard !state.hasShownProlongedLocationUnavailableNotice, state.userLocation != nil, let date = state.lastLocationResolvedAt else { return false }
        return Date().timeIntervalSince(date) >= Self.prolongedLocationUnavailableInterval
    }

    func initialMapDataLoadEffect() -> Effect<Action> {
        .send(.initialLocationRequested)
    }

    func mapServiceEffect(_ input: MapServiceInAction) -> Effect<Action> {
        let mapService = mapService
        return .run { send in
            guard let output = await mapService.perform(input) else { return }
            await send(.serviceOutput(output))
        }
    }

    func userHeadingUpdatesEffect(origin: RodiCoordinate) -> Effect<Action> {
        let mapService = mapService
        return .run { send in
            await send(.delegate(.prepareInitialSearch(origin: origin)))
            await send(.periodicLocationRefreshSchedulingRequested)
            for await degrees in mapService.userHeadingUpdates() {
                guard !Task.isCancelled else { return }
                await send(.serviceOutput(.userHeadingUpdated(degrees)))
            }
        }
        .cancelTask(id: CancellationID.userHeadingUpdates)
    }

    func periodicLocationRefreshEffect() -> Effect<Action> {
        let delay = Self.periodicLocationRefreshNanoseconds
        return .run { send in
            do { try await Task.sleep(nanoseconds: delay) } catch { return }
            guard !Task.isCancelled else { return }
            await send(.periodicLocationRefreshTimerFired)
        }
        .cancelTask(id: CancellationID.periodicLocationRefresh)
    }

    func markerRenderingEffect(_ markers: [RodiMapMarker], generation: Int, reportsInitialCompletion: Bool) -> Effect<Action> {
        let snapshots = markerRenderingService.progressiveSnapshots(for: markers)
        return .run { send in
            for await snapshot in snapshots {
                guard !Task.isCancelled else { return }
                await send(.markerRenderBatchUpdated(snapshot, generation: generation))
            }
            guard reportsInitialCompletion, !Task.isCancelled else { return }
            do { try await Task.sleep(nanoseconds: 120_000_000) } catch { return }
            guard !Task.isCancelled else { return }
            await send(.initialMarkerRenderingFinished(generation: generation))
        }
        .cancelTask(id: CancellationID.progressiveMarkerRendering)
    }

    func actions(_ actions: [Action]) -> Effect<Action> {
        .run { send in
            for action in actions { await send(action) }
        }
    }

    func authorizationRefreshEffect(source: LocationRequestSource) -> Effect<Action> {
        let mapService = mapService
        return .run { send in
            await send(.delegate(.showLocationSettingsAlert(false)))
            guard let output = await mapService.perform(.requestCurrentLocation(source: source)) else { return }
            await send(.serviceOutput(output))
        }
    }

    private func effects(_ actions: [Action], cancellation: CancellationID? = nil) -> Effect<Action> {
        let effect = self.actions(actions)
        guard let cancellation else { return effect }
        return effect.cancelTask(id: cancellation)
    }
}
