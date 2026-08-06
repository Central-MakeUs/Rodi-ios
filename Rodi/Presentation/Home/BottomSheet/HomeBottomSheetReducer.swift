import Foundation

struct HomeBottomSheetReducer: Reducer {
    enum Route: Equatable {
        case recommendList
        case filter
        case courseDetail
        case parkingDetail
    }

    struct State {
        var route: Route = .recommendList
        var resolvingPlaceID: Int?
        var isRecommendationPlaceResolution = false
        var recommendList = RecommendListBottomSheetReducer.State()
        var filter = FilterBottomSheetReducer.State()
        var courseDetail = CourseDetailBottomSheetReducer.State()
        var parkingDetail = ParkingDetailBottomSheetReducer.State()
    }

    enum Action {
        case showRecommendList
        case showFilter
        case resolvePlace(id: Int)
        case resolveRecommendedPlace(id: Int)
        case placeResolved(PlaceDetail)
        case placeDetailPresentationFinished(id: Int)
        case placeResolutionAuthenticationRequired(id: Int)
        case placeResolutionFailed(id: Int, message: String)
        case recommendList(RecommendListBottomSheetReducer.Action)
        case filter(FilterBottomSheetReducer.Action)
        case courseDetail(CourseDetailBottomSheetReducer.Action)
        case parkingDetail(ParkingDetailBottomSheetReducer.Action)
        case delegate(Delegate)
    }

    enum Delegate {
        case mapPlaceResolved(PlaceDetail)
        case mapRouteOverlayChanged(RodiRouteOverlay?)
        case mapFocusRequested(RodiCoordinate)
        case mapDetailDismissed
        case recommendationPresentationChanged(
            isBottomTabBarVisible: Bool,
            isResearchButtonVisible: Bool
        )
        case requestAuthentication
        case showSnackbar(String)
    }

    private let placeRepository: PlaceRepository
    private let recommendListReducer: RecommendListBottomSheetReducer
    private let filterReducer: FilterBottomSheetReducer
    private let courseDetailReducer: CourseDetailBottomSheetReducer
    private let parkingDetailReducer: ParkingDetailBottomSheetReducer

    init(dependencies: AppDependencies) {
        let hasActiveSession = {
            [dependencies.tokenStore.accessToken, dependencies.tokenStore.refreshToken]
                .contains { $0?.isEmpty == false }
        }
        placeRepository = dependencies.placeRepository

        recommendListReducer = RecommendListBottomSheetReducer(
            placeRepository: dependencies.placeRepository,
            hasActiveSession: hasActiveSession
        )
        filterReducer = FilterBottomSheetReducer(
            memberRepository: dependencies.memberRepository,
            hasActiveSession: hasActiveSession
        )
        courseDetailReducer = CourseDetailBottomSheetReducer(
            placeRepository: dependencies.placeRepository,
            hasActiveSession: hasActiveSession
        )
        parkingDetailReducer = ParkingDetailBottomSheetReducer(
            placeRepository: dependencies.placeRepository,
            hasActiveSession: hasActiveSession
        )
    }
}


// MARK: - Reduce
extension HomeBottomSheetReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .showRecommendList:
            state.route = .recommendList

        case .showFilter:
            state.route = .filter

        case .resolvePlace(let id):
            guard state.resolvingPlaceID == nil else { return .none }
            state.resolvingPlaceID = id
            state.isRecommendationPlaceResolution = false
            return resolvePlaceEffect(id: id)

        case .resolveRecommendedPlace(let id):
            guard state.resolvingPlaceID == nil else { return .none }
            state.resolvingPlaceID = id
            state.isRecommendationPlaceResolution = true
            return resolvePlaceEffect(id: id)

        case .placeResolved(let detail):
            guard state.resolvingPlaceID != nil else { return .none }
            state.resolvingPlaceID = nil
            state.isRecommendationPlaceResolution = false
            state.route = detail.type == .course ? .courseDetail : .parkingDetail
            let detailAction: Action = detail.type == .course
                ? .courseDetail(.present(detail, source: "home"))
                : .parkingDetail(.present(detail, source: "home"))
            return actions([
                detailAction,
                .delegate(.mapPlaceResolved(detail)),
                .placeDetailPresentationFinished(id: detail.id)
            ])

        case .placeDetailPresentationFinished:
            return .none

        case .placeResolutionAuthenticationRequired(let id):
            guard state.resolvingPlaceID == id else { return .none }
            state.resolvingPlaceID = nil
            if state.isRecommendationPlaceResolution {
                state.isRecommendationPlaceResolution = false
                return .send(.delegate(.requestAuthentication))
            }
            state.isRecommendationPlaceResolution = false
            return actions([
                .delegate(.mapDetailDismissed),
                .delegate(.requestAuthentication)
            ])

        case .placeResolutionFailed(let id, let message):
            guard state.resolvingPlaceID == id else { return .none }
            state.resolvingPlaceID = nil
            if state.isRecommendationPlaceResolution {
                state.isRecommendationPlaceResolution = false
                return .send(.delegate(.showSnackbar(message)))
            }
            state.isRecommendationPlaceResolution = false
            return actions([
                .delegate(.mapDetailDismissed),
                .delegate(.showSnackbar(message))
            ])

        case .recommendList(let action):
            if case .delegate(let delegate) = action {
                return reduceRecommendDelegate(delegate, state: &state)
            }
            return recommendListReducer.reduce(&state.recommendList, with: action).map(Action.recommendList)

        case .filter(let action):
            if case .delegate(let delegate) = action {
                return reduceFilterDelegate(delegate, state: &state)
            }
            return filterReducer.reduce(&state.filter, with: action).map(Action.filter)

        case .courseDetail(let action):
            if case .delegate(let delegate) = action {
                return reduceCourseDelegate(delegate, state: &state)
            }
            return courseDetailReducer.reduce(&state.courseDetail, with: action).map(Action.courseDetail)

        case .parkingDetail(let action):
            if case .delegate(let delegate) = action {
                return reduceParkingDelegate(delegate, state: &state)
            }
            return parkingDetailReducer.reduce(&state.parkingDetail, with: action).map(Action.parkingDetail)

        case .delegate:
            return .none
        }
        return .none
    }

    private func reduceRecommendDelegate(
        _ delegate: RecommendListBottomSheetReducer.Delegate, state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .resolvePlace(let item):
            state.recommendList.presentation = .medium
            return actions([
                .delegate(.mapFocusRequested(RodiCoordinate(
                    latitude: item.latitude,
                    longitude: item.longitude
                ))),
                .resolveRecommendedPlace(id: item.id)
            ])

        case .presentFilter:
            return actions([
                .recommendList(.present),
                .filter(.present),
                .showFilter
            ])

        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))

        case let .displayStateChanged(presentation, showsResearchButton):
            return .send(.delegate(.recommendationPresentationChanged(
                isBottomTabBarVisible: presentation == .collapsed,
                isResearchButtonVisible: showsResearchButton
            )))
        }
    }

    private func reduceFilterDelegate(
        _ delegate: FilterBottomSheetReducer.Delegate, state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .applied:
            state.route = .recommendList
            return actions([
                .recommendList(.reloadAfterFilter),
                .recommendList(.present),
                .showRecommendList
            ])

        case .dismissed:
            state.route = .recommendList
            return actions([
                .recommendList(.present),
                .showRecommendList
            ])

        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }

    private func reduceCourseDelegate(
        _ delegate: CourseDetailBottomSheetReducer.Delegate, state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .dismissed:
            return dismissDetail(state: &state)

        case .routeOverlayChanged(let overlay):
            return .send(.delegate(.mapRouteOverlayChanged(overlay)))

        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }

    private func reduceParkingDelegate(
        _ delegate: ParkingDetailBottomSheetReducer.Delegate, state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .dismissed:
            return dismissDetail(state: &state)

        case .focusMap(let coordinate):
            return .send(.delegate(.mapFocusRequested(coordinate)))

        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }

    private func dismissDetail(state: inout State) -> Effect<Action> {
        state.route = .recommendList
        state.recommendList.presentation = .collapsed
        return .send(.delegate(.mapDetailDismissed))
    }
}


// MARK: - Effect
extension HomeBottomSheetReducer {

    private func resolvePlaceEffect(id: Int) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in
            do {
                await send(.placeResolved(try await repository.fetchPlaceDetail(id: id)))
            } catch is CancellationError {
                return
            } catch {
                await send(requiresAuthentication(error)
                    ? .placeResolutionAuthenticationRequired(id: id)
                    : .placeResolutionFailed(id: id, message: "장소 상세 정보를 불러오지 못했어요."))
            }
        }
        .cancelTask(id: BottomSheetEffectID.placeDetailLoading)
    }

    private func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401): true
        case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default: false
        }
    }

    private func actions(_ actions: [Action]) -> Effect<Action> {
        .run { send in
            for action in actions {
                await send(action)
            }
        }
    }

}
