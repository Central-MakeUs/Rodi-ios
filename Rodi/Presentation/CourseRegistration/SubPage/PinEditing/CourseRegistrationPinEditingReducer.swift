import Foundation

struct CourseRegistrationPinEditingReducer: Reducer {
    struct State: Equatable {
        let target: CourseRegistrationInputTarget
        let originalPlace: CourseRegistrationSelectedPlace
        var cameraTarget: RodiCoordinate
        var cameraRequestID = 0
        var locationRequestRevision = 0
        var addressRequestRevision = 0
        var completionRevision = 0
        var candidateCoordinate: RodiCoordinate?
        var candidateAddress: String?
        var temporaryPlace: CourseRegistrationSelectedPlace?
        var isAddressResolving = false
        var isCurrentLocationActive = false
        var isSaving = false

        init(target: CourseRegistrationInputTarget, originalPlace: CourseRegistrationSelectedPlace) {
            self.target = target
            self.originalPlace = originalPlace
            cameraTarget = originalPlace.coordinate
        }
    }

    enum Action {
        case currentLocationTapped
        case deactivated
        case currentLocationResolved(Int, CourseRegistrationMapService.CurrentLocationResult)
        case viewportChanged(RodiCoordinate, isUserInitiated: Bool)
        case addressTapped
        case searchResultSelected(CourseRegistrationPlaceSearchItem)
        case candidateAddressFinished(AddressRequest, Result<String, CourseRegistrationAddressLookupError>)
        case selectionTapped
        case retryTapped
        case backTapped
        case completionTapped([RodiRouteOverlayPoint])
        case routeFinished(Int, Result<[RodiCoordinate], KakaoDirectionsError>)
        case delegate(Delegate)
    }

    enum Delegate {
        case openSearch
        case cancelled
        case completed(CourseRegistrationInputTarget, CourseRegistrationSelectedPlace, [RodiCoordinate]?)
        case showError(String)
    }

    private enum EffectID: Hashable {
        case work
    }

    struct AddressRequest: Equatable {
        let revision: Int
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
        case .deactivated:
            state.locationRequestRevision += 1
            state.addressRequestRevision += 1
            state.completionRevision += 1
            state.isCurrentLocationActive = false
            state.isAddressResolving = false
            state.isSaving = false
            return .cancel(id: EffectID.work)

        case .currentLocationTapped:
            guard state.temporaryPlace == nil else { return .none }
            state.locationRequestRevision += 1
            state.isCurrentLocationActive = true
            return requestCurrentLocation(revision: state.locationRequestRevision)

        case .currentLocationResolved(let revision, let result):
            guard revision == state.locationRequestRevision, state.temporaryPlace == nil else { return .none }
            if case let .resolved(coordinate) = result {
                state.cameraTarget = coordinate
                state.cameraRequestID += 1
                state.candidateCoordinate = coordinate
                state.candidateAddress = nil
                state.isCurrentLocationActive = false
                return .none
            }
            state.isCurrentLocationActive = false
            if let message = currentLocationFailureMessage(for: result) {
                RodiAnalytics.track(.courseRegistrationFailed(stage: "current_location"))
                return .send(.delegate(.showError(message)))
            }

        case .viewportChanged(let center, let isUserInitiated):
            guard isUserInitiated, state.temporaryPlace == nil else { return .none }
            state.isCurrentLocationActive = false
            state.candidateCoordinate = center
            state.candidateAddress = nil

        case .addressTapped:
            return .send(.delegate(.openSearch))

        case .searchResultSelected(let result):
            guard let coordinate = result.coordinate else {
                return .send(.delegate(.showError("선택한 장소의 위치를 불러오지 못했어요.")))
            }
            state.cameraTarget = coordinate
            state.cameraRequestID += 1
            state.candidateCoordinate = coordinate
            state.candidateAddress = nil
            state.isCurrentLocationActive = false
            return requestCandidateAddress(coordinate, state: &state)

        case .candidateAddressFinished(let request, let result):
            guard request.revision == state.addressRequestRevision, state.temporaryPlace == nil else { return .none }
            state.isAddressResolving = false
            switch result {
            case .success(let address):
                state.candidateCoordinate = request.coordinate
                state.candidateAddress = address
                state.temporaryPlace = .init(name: address, coordinate: request.coordinate)
            case .failure(let error):
                return .send(.delegate(.showError(error.userMessage)))
            }

        case .selectionTapped:
            guard let coordinate = state.candidateCoordinate,
                  !state.isAddressResolving,
                  state.temporaryPlace == nil
            else {
                return .none
            }
            return requestCandidateAddress(coordinate, state: &state)

        case .retryTapped:
            guard let temporary = state.temporaryPlace else { return .none }
            state.temporaryPlace = nil
            state.cameraTarget = temporary.coordinate
            state.cameraRequestID += 1
            state.candidateCoordinate = nil
            state.candidateAddress = nil

        case .backTapped:
            return .send(.delegate(.cancelled))

        case .completionTapped(let points):
            guard !state.isSaving else { return .none }
            guard let temporary = state.temporaryPlace else { return .none }
            guard points.count >= 2 else {
                return .send(.delegate(.completed(state.target, temporary, nil)))
            }
            state.isSaving = true
            state.completionRevision += 1
            return requestRoute(points: points, revision: state.completionRevision)

        case .routeFinished(let revision, let result):
            guard revision == state.completionRevision, state.isSaving else { return .none }
            state.isSaving = false
            switch result {
            case .success(let path):
                guard let temporary = state.temporaryPlace else { return .none }
                return .send(.delegate(.completed(state.target, temporary, path)))
            case .failure:
                return .send(.delegate(.showError("핀 위치를 수정하지 못했어요. 잠시 후 다시 시도해주세요.")))
            }

        case .delegate:
            return .none
        }

        return .none
    }

    private func requestCurrentLocation(revision: Int) -> Effect<Action> {
        .run { send in
            await send(.currentLocationResolved(revision, await mapService.requestCurrentLocation()))
        }
        .cancelTask(id: EffectID.work)
    }

    private func requestCandidateAddress(
        _ coordinate: RodiCoordinate,
        state: inout State
    ) -> Effect<Action> {
        state.addressRequestRevision += 1
        state.isAddressResolving = true
        let request = AddressRequest(revision: state.addressRequestRevision, coordinate: coordinate)
        return .run { send in
            do {
                await send(.candidateAddressFinished(request, .success(try await mapService.reverseGeocode(coordinate))))
            } catch is CancellationError {
                return
            } catch let error as CourseRegistrationAddressLookupError {
                await send(.candidateAddressFinished(request, .failure(error)))
            } catch {
                await send(.candidateAddressFinished(request, .failure(.networkFailed)))
            }
        }
        .cancelTask(id: EffectID.work)
    }

    private func requestRoute(
        points: [RodiRouteOverlayPoint],
        revision: Int
    ) -> Effect<Action> {
        .run { send in
            do {
                await send(.routeFinished(revision, .success(try await directionsService.fetchRoute(points: points))))
            } catch is CancellationError {
                return
            } catch let error as KakaoDirectionsError {
                await send(.routeFinished(revision, .failure(error)))
            } catch {
                await send(.routeFinished(revision, .failure(.networkFailed("unknown"))))
            }
        }
        .cancelTask(id: EffectID.work)
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
}
