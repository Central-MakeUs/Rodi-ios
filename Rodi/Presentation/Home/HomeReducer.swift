//
//  HomeReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct HomeReducer: Reducer {
    typealias State = HomeState
    typealias MapAction = HomeMapReducer.Action

    struct Dependencies {
        let tokenStore: TokenStoring
        let placeRepository: PlaceRepository
        let practiceRepository: PracticeRepository
        let recentSearchRepository: RecentSearchRepository
        let reviewRepository: ReviewRepository
        let memberRepository: MemberRepository
        let practiceMeasurementStore: PracticeMeasurementStoring
        let practiceTrackingService: PracticeTrackingService
    }

    enum Action {
        case map(MapAction)
        case bottomSheet(HomeBottomSheetReducer.Action)
        case search(HomeSearchReducer.Action)
        case presentation(PresentationAction)
        case delegate(Delegate)
        #if DEBUG
        case debugReviewTestRequested
        #endif
    }

    enum Delegate {
        case requestAuthentication
        case reviewWritingRequested(ReviewWriteRequest)
        case reviewEditingRequested(Int)
        #if DEBUG
        case reviewTestRequested
        #endif
    }

    enum PresentationAction {
        case setLocationSettingsAlertPresented(Bool)
        case snackbarRequestHandled
    }

    private let mapReducer: HomeMapReducer
    private let bottomSheetReducer: HomeBottomSheetReducer
    private let searchReducer: HomeSearchReducer
    private let delegateHandler: (Delegate) -> Void

    init(dependencies: Dependencies, delegateHandler: @escaping (Delegate) -> Void = { _ in }) {
        let hasActiveSession = {
            [dependencies.tokenStore.accessToken, dependencies.tokenStore.refreshToken]
                .contains { $0?.isEmpty == false }
        }
        mapReducer = HomeMapReducer(
            dependencies: .init(
                placeRepository: dependencies.placeRepository,
                hasActiveSession: hasActiveSession
            )
        )
        bottomSheetReducer = HomeBottomSheetReducer(
            dependencies: .init(
                tokenStore: dependencies.tokenStore,
                placeRepository: dependencies.placeRepository,
                practiceRepository: dependencies.practiceRepository,
                reviewRepository: dependencies.reviewRepository,
                memberRepository: dependencies.memberRepository,
                practiceMeasurementStore: dependencies.practiceMeasurementStore,
                practiceTrackingService: dependencies.practiceTrackingService,
                routeGuidanceService: .init()
            )
        )
        searchReducer = HomeSearchReducer(
            placeRepository: dependencies.placeRepository,
            recentSearchRepository: dependencies.recentSearchRepository
        )
        self.delegateHandler = delegateHandler
    }

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
        case .delegate(let delegate):
            delegateHandler(delegate)
            return .none
        #if DEBUG
        case .debugReviewTestRequested:
            return .send(.delegate(.reviewTestRequested))
        #endif
        }
    }
}

private extension HomeReducer {
    func reduceMap(_ state: inout State, action: MapAction) -> Effect<Action> {
        guard case .delegate(let delegate) = action else {
            return mapReducer.reduce(&state.map, with: action).map(Action.map)
        }
        switch delegate {
        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))
        case .showLocationSettingsAlert(let isPresented):
            state.presentation.isLocationSettingsAlertPresented = isPresented
        case .showSnackbar(let message):
            state.presentation.pendingSnackbar = ToastStruct(message: message, state: .error)
        case .bottomTabBarVisibilityChanged(let visible):
            state.presentation.isBottomTabBarVisible = visible
        case .searchEntryRequested(let origin):
            state.search = .init()
            state.presentation.searchOrigin = origin
            state.presentation.isSearchPresented = true
        case .searchSelectionClearRequested:
            state.search = .init()
            return .send(.bottomSheet(.clearSearchSelection))
        case .resolvePlace(let id):
            return .send(.bottomSheet(.resolvePlace(id: id)))
        case .resolveSavedPlace(let place):
            return .send(.bottomSheet(.resolveSavedPlace(place)))
        case .prepareForCurrentLocation:
            return .send(.bottomSheet(.prepareForCurrentLocation))
        case .reloadCurrentViewport(let origin):
            return .send(.bottomSheet(.recommendList(.reloadCurrentViewport(origin: origin))))
        case let .viewportChanged(viewport, center, isUserInitiated):
            return .send(.bottomSheet(.recommendList(.viewportChanged(viewport: viewport, center: center, isUserInitiated: isUserInitiated))))
        case .reloadAfterRegionViewport(let origin):
            return .send(.bottomSheet(.recommendList(.reloadAfterRegionViewport(origin: origin))))
        case .presentRecommendListForRegion(let origin):
            return .send(.bottomSheet(.presentRecommendListForRegion(origin: origin)))
        case .prepareInitialSearch(let origin):
            return .send(.bottomSheet(.recommendList(.prepareInitialSearch(origin: origin))))
        }
        return .none
    }

    func reduceBottomSheet(_ state: inout State, action: HomeBottomSheetReducer.Action) -> Effect<Action> {
        guard case .delegate(let delegate) = action else {
            return bottomSheetReducer.reduce(&state.bottomSheet, with: action).map(Action.bottomSheet)
        }
        switch delegate {
        case .mapPlaceResolved(let detail):
            return .send(.map(.placeResolved(detail)))
        case .mapSearchSelectionRequested(let name):
            return .send(.map(.searchPlaceSelected(name)))
        case .mapRouteOverlayChanged(let overlay):
            return .send(.map(.routeOverlayChanged(overlay)))
        case .mapFocusRequested(let coordinate):
            return .send(.map(.focusRequested(coordinate)))
        case .mapDetailDismissed:
            return .send(.map(.detailDismissed))
        case .currentLocationReady:
            return .send(.map(.currentLocationReady))
        case let .recommendationPresentationChanged(isBottomTabBarVisible, isResearchButtonVisible):
            state.presentation.isBottomTabBarVisible = isBottomTabBarVisible
            return .send(.map(.researchButtonVisibilityChanged(isResearchButtonVisible)))
        case .recommendationCollapsed:
            return .send(.map(.recommendationCollapsed))
        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))
        case .showSnackbar(let message):
            state.presentation.pendingSnackbar = ToastStruct(message: message, state: .error)
        case .reviewWritingRequested(let request):
            return .send(.delegate(.reviewWritingRequested(request)))
        case .reviewEditingRequested(let reviewID):
            return .send(.delegate(.reviewEditingRequested(reviewID)))
        }
        return .none
    }

    func reduceSearch(_ state: inout State, action: HomeSearchReducer.Action) -> Effect<Action> {
        guard case .delegate(let delegate) = action else {
            return searchReducer.reduce(&state.search, with: action).map(Action.search)
        }
        switch delegate {
        case let .placeSelected(id, name):
            state.presentation.isSearchPresented = false
            state.presentation.searchOrigin = nil
            state.search = .init()
            return actions([.map(.searchPlaceSelected(name)), .bottomSheet(.resolvePlace(id: id))])
        case let .regionSelected(name, center):
            state.presentation.isSearchPresented = false
            state.presentation.searchOrigin = nil
            state.search = .init()
            return .send(.map(.regionSelected(name: name, center: center)))
        case .dismissed:
            state.presentation.isSearchPresented = false
            state.presentation.searchOrigin = nil
        case .showSnackbar(let message):
            state.presentation.pendingSnackbar = ToastStruct(message: message, state: .error)
        }
        return .none
    }

    func reducePresentation(_ state: inout State, action: PresentationAction) -> Effect<Action> {
        switch action {
        case .setLocationSettingsAlertPresented(let isPresented):
            state.presentation.isLocationSettingsAlertPresented = isPresented
        case .snackbarRequestHandled:
            state.presentation.pendingSnackbar = nil
        }
        return .none
    }

    func actions(_ actions: [Action]) -> Effect<Action> {
        .run { send in
            for action in actions { await send(action) }
        }
    }
}
