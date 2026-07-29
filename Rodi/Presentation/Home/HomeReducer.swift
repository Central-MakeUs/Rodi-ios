//
//  HomeReducer.swift
//  Rodi
//

import Foundation

/// Home feature 간의 명시적인 신호만 연결하는 조정자다.
/// 지도와 바텀싯의 도메인 로직은 각각의 child reducer가 소유한다.
struct HomeReducer: Reducer {
    struct State {
        var map = HomeMapReducer.State()
        var bottomSheet = HomeBottomSheetReducer.State()
        var presentation = HomePresentationState()

        var visibleItems: [RodiCourseItem] {
            map.items
        }

        var overlayState: HomeOverlayState? {
            if map.isRetryingAfterNetworkFailure { return .loading(.map) }
            if map.isNetworkUnavailable { return .networkUnavailable }
            if let mapErrorMessage = map.errorMessage { return .mapUnavailable(message: mapErrorMessage) }
            if map.isLoading { return .loading(.map) }
            return nil
        }

        var displayedMapMarkers: [RodiMapMarker] {
            if bottomSheet.selectedItem?.type == .course,
               bottomSheet.selectedRouteOverlay != nil {
                return []
            }

            if let selectedItem = bottomSheet.selectedItem {
                return selectedItem.mapMarker.map {
                    [RodiMapMarker(
                        id: $0.id,
                        kind: $0.kind,
                        title: $0.title,
                        coordinate: $0.coordinate,
                        isSelected: true
                    )]
                } ?? []
            }

            return map.visibleMapMarkers
        }
    }

    enum Action {
        case map(HomeMapReducer.Action)
        case bottomSheet(HomeBottomSheetReducer.Action)
        case presentation(HomePresentationReducer.Action)
    }

    private let mapReducer = HomeMapReducer()
    private let bottomSheetReducer: HomeBottomSheetReducer
    private let presentationReducer = HomePresentationReducer()

    init(
        placeRepository: PlaceRepository,
        hasActiveSession: @escaping () -> Bool = {
            let tokenStore = AuthDependencyContainer.shared.tokenStore
            return [tokenStore.accessToken, tokenStore.refreshToken]
                .contains { $0?.isEmpty == false }
        }
    ) {
        bottomSheetReducer = HomeBottomSheetReducer(
            placeRepository: placeRepository,
            hasActiveSession: hasActiveSession
        )
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .map(.delegate(let delegate)):
            switch delegate {
            case .prepareInitialPlaceListSearch(origin: let origin):
                
                // TODO: return .send() need plz Fix
                return .run { send in
                    await send(.bottomSheet(.placeList(.prepareInitialSearch(origin: origin))))
                }
            }
            
        case .bottomSheet(.delegate(let delegate)):
            return handleBottomSheetDelegate(delegate, state: &state)
            
            // MARK: Scope
        case .map(let action):
            return mapReducer
                .reduce(&state.map, with: action)
                .map(Action.map)
            
        case .bottomSheet(let action):
            return bottomSheetReducer
                .reduce(&state.bottomSheet, with: action)
                .map(Action.bottomSheet)
            
        case .presentation(let action):
            return presentationReducer
                .reduce(&state.presentation, with: action)
                .map(Action.presentation)
        }
    }

    private func handleBottomSheetDelegate(
        _ delegate: HomeBottomSheetReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .focusMapOnParking(let coordinate):
            return .run { send in
                await send(.map(.focusParking(coordinate)))
            }

        case .showSnackbar(let message):
            return .run { send in
                await send(.presentation(.showSnackbar(message)))
            }

        case .requestAuthentication:
            return .run { send in
                await send(.presentation(.requestAuthentication))
            }
        }

    }
}
