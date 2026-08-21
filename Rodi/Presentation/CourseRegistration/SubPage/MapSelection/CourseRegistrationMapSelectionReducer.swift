import Foundation

struct CourseRegistrationMapSelectionReducer: Reducer {
    struct State: Equatable {
        var waypoints: [CourseRegistrationWaypoint] = []
        var selectedPlaces: [CourseRegistrationInputTarget: CourseRegistrationSelectedPlace] = [:]
        var routePath: [RodiCoordinate] = []
        var isRouteLoading = false
        var routeRequestRevision = 0
        var map = CourseRegistrationMapState()
        var hasTrackedRegistrationOpened = false

        init(isCourseTutorialCompleted: Bool = false) {
            if isCourseTutorialCompleted {
                map.selectionTarget = .start
            }
        }

        var hasInput: Bool {
            !waypoints.isEmpty || !selectedPlaces.isEmpty || !routePath.isEmpty
        }

        /// 코스는 출발지 → 도착지 → 경유지 순으로만 장소 검색을 시작한다.
        func canSearch(for target: CourseRegistrationInputTarget) -> Bool {
            switch target {
            case .start:
                selectedPlaces[.start] == nil
            case .destination:
                selectedPlaces[.start] != nil && selectedPlaces[.destination] == nil
            case .waypoint(let id):
                selectedPlaces[.destination] != nil
                    && selectedPlaces[.waypoint(id)] == nil
                    && waypoints.contains(where: { $0.id == id })
            }
        }

        var canAddWaypoint: Bool {
            selectedPlaces[.destination] != nil
                && map.selectionTarget == nil
                && waypoints.count < 3
        }

        func routePoints(
            replacing replacement: (CourseRegistrationInputTarget, CourseRegistrationSelectedPlace)? = nil
        ) -> [RodiRouteOverlayPoint] {
            orderedTargets.enumerated().compactMap { index, target in
                let place = replacement?.0 == target ? replacement?.1 : selectedPlaces[target]
                guard let place else { return nil }
                return .init(
                    id: index,
                    sequence: index,
                    role: target.routePointRole,
                    name: place.name,
                    coordinate: place.coordinate
                )
            }
        }

        func target(at pointID: Int) -> CourseRegistrationInputTarget? {
            guard orderedTargets.indices.contains(pointID) else { return nil }
            return orderedTargets[pointID]
        }

        private var orderedTargets: [CourseRegistrationInputTarget] {
            var targets: [CourseRegistrationInputTarget] = []
            if selectedPlaces[.start] != nil {
                targets.append(.start)
            }
            targets += waypoints.compactMap { waypoint in
                selectedPlaces[.waypoint(waypoint.id)] == nil ? nil : .waypoint(waypoint.id)
            }
            if selectedPlaces[.destination] != nil {
                targets.append(.destination)
            }
            return targets
        }
    }

    enum Action {
        case prepareStartSelection
        case appeared
        case deactivated
        case closeTapped
        case reset
        case waypointAddTapped
        case waypointRemoveTapped(UUID)
        case currentLocationTapped
        case currentLocationResolved(LocationRequest, CourseRegistrationMapService.CurrentLocationResult)
        case viewportChanged(RodiCoordinate, isUserInitiated: Bool)
        case initialLocationRequested
        case candidateAddressRequested(CourseRegistrationInputTarget, RodiCoordinate, debounce: Bool)
        case placeSelectionTapped
        case reverseGeocodingFinished(AddressRequest, Result<String, CourseRegistrationAddressLookupError>)
        case registrationCompletionTapped
        case inputTargetTapped(CourseRegistrationInputTarget)
        case searchResultSelected(CourseRegistrationInputTarget, CourseRegistrationPlaceSearchItem)
        case regionSelected(CourseRegistrationInputTarget, CourseRegistrationRegionSuggestion)
        case routePointTapped(Int)
        case pinEditApplied(CourseRegistrationInputTarget, CourseRegistrationSelectedPlace, [RodiCoordinate]?)
        case initialRouteFinished(Int, Result<[RodiCoordinate], KakaoDirectionsError>)
        case cancelLocationTask
        case cancelAddressTask
        case cancelRouteTask
        case delegate(Delegate)
    }

    enum Delegate {
        case openSearch(CourseRegistrationInputTarget)
        case openPinEdit(CourseRegistrationInputTarget, CourseRegistrationSelectedPlace)
        case openDetails(CourseRegistrationDetailsContext)
        case closeRequested(hasInput: Bool)
        case showError(String)
    }

    private enum EffectID: Hashable {
        case location
        case address
        case route
    }

    struct LocationRequest: Equatable {
        enum Source: Equatable {
            case initial
            case userAction
        }

        let revision: Int
        let source: Source
    }

    struct AddressRequest: Equatable {
        let revision: Int
        let target: CourseRegistrationInputTarget
        let coordinate: RodiCoordinate
    }

    private let mapService: CourseRegistrationMapService
    private let directionsService: KakaoDirectionsService

    init(
        mapService: CourseRegistrationMapService? = nil,
        directionsService: KakaoDirectionsService = .init()
    ) {
        self.mapService = mapService ?? CourseRegistrationMapService()
        self.directionsService = directionsService
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .prepareStartSelection:
            beginSelection(.start, state: &state)

        case .appeared:
            guard !state.map.hasRequestedInitialLocation else { return .none }
            if !state.hasTrackedRegistrationOpened {
                state.hasTrackedRegistrationOpened = true
                RodiAnalytics.track(.courseRegistrationOpened)
            }
            state.map.hasRequestedInitialLocation = true
            guard let target = state.map.selectionTarget else { return .none }
            let coordinate = state.map.cameraTarget
            return .run { send in
                await send(.candidateAddressRequested(target, coordinate, debounce: false))
                await send(.initialLocationRequested)
            }

        case .deactivated:
            state.map.locationRequestRevision += 1
            state.map.addressRequestRevision += 1
            state.routeRequestRevision += 1
            state.map.isCurrentLocationActive = false
            state.map.isAddressResolving = false
            state.isRouteLoading = false
            return cancelAllTasks()

        case .closeTapped:
            return .send(.delegate(.closeRequested(hasInput: state.hasInput)))

        case .reset:
            state = .init()
            return cancelAllTasks()

        case .waypointAddTapped:
            guard state.canAddWaypoint else { return .none }
            let waypoint = CourseRegistrationWaypoint()
            state.waypoints.append(waypoint)
            state.routePath = []
            RodiAnalytics.track(
                .courseRegistrationWaypointChanged(action: "added", waypointCount: state.waypoints.count)
            )
            beginSelection(.waypoint(waypoint.id), state: &state)

        case .waypointRemoveTapped(let id):
            guard state.waypoints.contains(where: { $0.id == id }) else { return .none }
            state.waypoints.removeAll { $0.id == id }
            state.selectedPlaces.removeValue(forKey: .waypoint(id))
            state.routePath = []
            if state.map.routeFailureTarget == .waypoint(id) {
                state.map.routeFailureTarget = nil
            }
            if state.map.lastRouteRequestTarget == .waypoint(id) {
                state.map.lastRouteRequestTarget = nil
            }
            RodiAnalytics.track(
                .courseRegistrationWaypointChanged(action: "removed", waypointCount: state.waypoints.count)
            )

            if state.map.selectionTarget == .waypoint(id) {
                state.map.selectionTarget = nil
                state.map.candidateCoordinate = nil
                state.map.candidateAddress = nil
                state.map.hasSelectedCurrentTarget = false
                state.map.isAddressResolving = false
                state.map.addressRequestRevision += 1
            }

            return refreshRouteAfterWaypointRemoval(state: &state)

        case .currentLocationTapped:
            state.map.locationRequestRevision += 1
            state.map.isCurrentLocationActive = true
            return requestCurrentLocation(.init(
                revision: state.map.locationRequestRevision,
                source: .userAction
            ))

        case .initialLocationRequested:
            state.map.locationRequestRevision += 1
            return requestCurrentLocation(.init(
                revision: state.map.locationRequestRevision,
                source: .initial
            ))

        case .currentLocationResolved(let request, let result):
            guard request.revision == state.map.locationRequestRevision else { return .none }
            if case let .resolved(coordinate) = result {
                state.map.cameraTarget = coordinate
                state.map.cameraRequestID += 1
                state.map.isCurrentLocationActive = false
                if let target = state.map.selectionTarget {
                    return .send(.candidateAddressRequested(target, coordinate, debounce: false))
                }
            }
            if request.source == .userAction {
                state.map.isCurrentLocationActive = false
                if let message = currentLocationFailureMessage(for: result) {
                    RodiAnalytics.track(.courseRegistrationFailed(stage: "current_location"))
                    return .send(.delegate(.showError(message)))
                }
            } else {
                state.map.isCurrentLocationActive = false
            }

        case .viewportChanged(let center, let isUserInitiated):
            guard isUserInitiated else { return .none }
            state.map.isCurrentLocationActive = false
            guard let target = state.map.selectionTarget else { return .none }
            return .send(.candidateAddressRequested(target, center, debounce: true))

        case .candidateAddressRequested(let target, let coordinate, let debounce):
            guard state.map.selectionTarget == target else { return .none }
            state.map.addressRequestRevision += 1
            state.map.candidateCoordinate = coordinate
            state.map.hasSelectedCurrentTarget = false
            state.map.isAddressResolving = true
            let request = AddressRequest(
                revision: state.map.addressRequestRevision,
                target: target,
                coordinate: coordinate
            )
            return reverseGeocode(request, debounce: debounce)

        case .placeSelectionTapped:
            guard let target = state.map.selectionTarget,
                  let coordinate = state.map.candidateCoordinate,
                  let address = state.map.candidateAddress,
                  !state.map.isAddressResolving
            else {
                return .none
            }
            state.selectedPlaces[target] = .init(name: address, coordinate: coordinate)
            state.map.hasSelectedCurrentTarget = true
            state.routePath = []
            RodiAnalytics.track(
                .courseRegistrationPointSelected(
                    inputType: target.analyticsInputType,
                    source: "map"
                )
            )
            return advanceAfterSelection(target, state: &state)

        case .reverseGeocodingFinished(let request, let result):
            guard request.revision == state.map.addressRequestRevision,
                  request.target == state.map.selectionTarget
            else {
                return .none
            }
            state.map.isAddressResolving = false
            switch result {
            case .success(let address):
                state.map.candidateCoordinate = request.coordinate
                state.map.candidateAddress = address
            case .failure(let error):
                return .send(.delegate(.showError(error.userMessage)))
            }

        case .registrationCompletionTapped:
            guard state.map.selectionTarget == nil,
                  state.selectedPlaces[.start] != nil,
                  state.selectedPlaces[.destination] != nil,
                  !state.isRouteLoading,
                  state.routePath.count >= 2
            else {
                if !state.isRouteLoading {
                    return .send(.delegate(.showError("도로 경로를 불러오지 못했어요. 잠시 후 다시 시도해주세요.")))
                }
                return .none
            }
            RodiAnalytics.track(.courseRegistrationDetailsOpened)
            return .send(.delegate(.openDetails(.init(
                waypoints: state.waypoints,
                selectedPlaces: state.selectedPlaces,
                routePath: state.routePath
            ))))

        case .inputTargetTapped(let target):
            guard state.canSearch(for: target) else { return .none }
            return .send(.delegate(.openSearch(target)))

        case .searchResultSelected(let target, let result):
            guard let coordinate = result.coordinate else {
                return .send(.delegate(.showError("선택한 장소의 위치를 불러오지 못했어요.")))
            }
            // 검색 중 시작된 위치 요청이 늦게 끝나도, 검색 결과 카메라 이동을 덮어쓰지 않게 한다.
            state.map.locationRequestRevision += 1
            beginSelection(target, cameraTarget: coordinate, state: &state)
            state.map.candidateCoordinate = coordinate
            state.map.candidateAddress = result.address.isEmpty ? result.title : result.address
            state.map.isCurrentLocationActive = false

        case .regionSelected(let target, let region):
            state.map.locationRequestRevision += 1
            beginSelection(target, cameraTarget: region.coordinate, state: &state)
            return .send(.candidateAddressRequested(target, region.coordinate, debounce: false))

        case .routePointTapped(let pointID):
            guard let target = state.target(at: pointID),
                  target != state.map.selectionTarget,
                  let original = state.selectedPlaces[target]
            else {
                return .none
            }
            return .send(.delegate(.openPinEdit(target, original)))

        case .pinEditApplied(let target, let replacement, let routePath):
            state.selectedPlaces[target] = replacement
            if let routePath {
                state.routePath = routePath
            }

        case .initialRouteFinished(let revision, let result):
            guard state.routeRequestRevision == revision, state.isRouteLoading else { return .none }
            state.isRouteLoading = false
            switch result {
            case .success(let path):
                state.routePath = path
                state.map.routeFailureTarget = nil
                RodiAnalytics.track(.courseRegistrationRoutePrepared(waypointCount: state.waypoints.count))
            case .failure:
                // 경로선만 준비하지 못한 경우에도 방금 선택한 지점은 지도에서 계속 확인할 수 있어야 한다.
                state.map.routeFailureTarget = state.map.lastRouteRequestTarget
                RodiAnalytics.track(.courseRegistrationFailed(stage: "route"))
                return .send(.delegate(.showError("도로 경로를 불러오지 못했어요. 잠시 후 다시 시도해주세요.")))
            }

        case .cancelLocationTask:
            return .cancel(id: EffectID.location)

        case .cancelAddressTask:
            return .cancel(id: EffectID.address)

        case .cancelRouteTask:
            return .cancel(id: EffectID.route)

        case .delegate:
            return .none
        }

        return .none
    }

    private func beginSelection(
        _ target: CourseRegistrationInputTarget,
        cameraTarget: RodiCoordinate? = nil,
        state: inout State
    ) {
        state.map.selectionTarget = target
        state.map.candidateCoordinate = nil
        state.map.candidateAddress = nil
        state.map.hasSelectedCurrentTarget = false
        state.map.isAddressResolving = false
        state.map.routeFailureTarget = nil
        if let cameraTarget {
            state.map.cameraTarget = cameraTarget
            state.map.cameraRequestID += 1
        }
    }

    private func requestCurrentLocation(_ request: LocationRequest) -> Effect<Action> {
        .run { send in
            await send(.currentLocationResolved(request, await mapService.requestCurrentLocation()))
        }
        .cancelTask(id: EffectID.location)
    }

    private func currentLocationFailureMessage(
        for result: CourseRegistrationMapService.CurrentLocationResult
    ) -> String? {
        switch result {
        case .resolved:
            nil
        case .permissionDenied:
            "현재 위치를 확인할 수 없어요. 위치 권한을 허용한 뒤 다시 시도해주세요."
        case .unavailable:
            "현재 위치를 확인할 수 없어요. 위치 서비스와 네트워크 상태를 확인한 뒤 다시 시도해주세요."
        }
    }

    private func reverseGeocode(_ request: AddressRequest, debounce: Bool) -> Effect<Action> {
        .run { send in
            do {
                if debounce {
                    try await Task.sleep(for: .milliseconds(250))
                }
                await send(.reverseGeocodingFinished(request, .success(try await mapService.reverseGeocode(request.coordinate))))
            } catch is CancellationError {
                return
            } catch let error as CourseRegistrationAddressLookupError {
                await send(.reverseGeocodingFinished(request, .failure(error)))
            } catch {
                await send(.reverseGeocodingFinished(request, .failure(.networkFailed)))
            }
        }
        .cancelTask(id: EffectID.address)
    }

    private func requestInitialRoute(
        points: [RodiRouteOverlayPoint],
        revision: Int
    ) -> Effect<Action> {
        .run { send in
            do {
                await send(.initialRouteFinished(revision, .success(try await directionsService.fetchRoute(points: points))))
            } catch is CancellationError {
                return
            } catch let error as KakaoDirectionsError {
                await send(.initialRouteFinished(revision, .failure(error)))
            } catch {
                await send(.initialRouteFinished(revision, .failure(.networkFailed("unknown"))))
            }
        }
        .cancelTask(id: EffectID.route)
    }

    private func advanceAfterSelection(
        _ target: CourseRegistrationInputTarget,
        state: inout State
    ) -> Effect<Action> {
        switch target {
        case .start:
            guard let start = state.selectedPlaces[.start] else { return .none }
            beginSelection(.destination, cameraTarget: start.coordinate, state: &state)
            state.map.candidateCoordinate = start.coordinate
            state.map.candidateAddress = start.name
            return .none
        case .destination, .waypoint:
            state.map.selectionTarget = nil
            state.map.candidateCoordinate = nil
            state.map.candidateAddress = nil
            state.map.hasSelectedCurrentTarget = false
            state.map.routeFailureTarget = nil
            let points = state.routePoints()
            guard points.count >= 2 else { return .none }
            state.isRouteLoading = true
            state.routeRequestRevision += 1
            state.map.lastRouteRequestTarget = target
            return requestInitialRoute(points: points, revision: state.routeRequestRevision)
        }
    }

    private func refreshRouteAfterWaypointRemoval(
        state: inout State
    ) -> Effect<Action> {
        let points = state.routePoints()
        state.routeRequestRevision += 1
        state.map.routeFailureTarget = nil
        state.map.lastRouteRequestTarget = nil

        guard points.count >= 2 else {
            state.isRouteLoading = false
            return .cancel(id: EffectID.route)
        }

        state.isRouteLoading = true
        return requestInitialRoute(points: points, revision: state.routeRequestRevision)
    }

    private func cancelAllTasks() -> Effect<Action> {
        .run { send in
            await send(.cancelLocationTask)
            await send(.cancelAddressTask)
            await send(.cancelRouteTask)
        }
    }
}

struct CourseRegistrationMapState: Equatable {
    var selectionTarget: CourseRegistrationInputTarget?
    var cameraTarget: RodiCoordinate = .seoulCityHall
    var cameraRequestID = 0
    var locationRequestRevision = 0
    var hasRequestedInitialLocation = false
    var addressRequestRevision = 0
    var candidateCoordinate: RodiCoordinate?
    var candidateAddress: String?
    /// 경로 요청이 실패해도 사용자가 방금 확정한 지점의 중앙 핀을 유지한다.
    var routeFailureTarget: CourseRegistrationInputTarget?
    var lastRouteRequestTarget: CourseRegistrationInputTarget?
    var hasSelectedCurrentTarget = false
    var isAddressResolving = false
    var isCurrentLocationActive = false
}
