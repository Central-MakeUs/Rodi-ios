//
//  HomeReducer.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct HomeReducer: Reducer {
    let placeRepository: PlaceRepository
    let hasActiveSession: () -> Bool

    init(
        placeRepository: PlaceRepository,
        hasActiveSession: @escaping () -> Bool = {
            let tokenStore = AuthDependencyContainer.shared.tokenStore
            return [tokenStore.accessToken, tokenStore.refreshToken]
                .contains { $0?.isEmpty == false }
        }
    ) {
        self.placeRepository = placeRepository
        self.hasActiveSession = hasActiveSession
    }

    func reduce(_ state: inout HomeState, with action: HomeAction) -> Effect<HomeAction> {
        switch action {
        case .viewAction(let action):
            return reduceViewAction(action, state: &state)

        case .runtimeAction(let action):
            return reduceRuntimeAction(action, state: &state)

        case .mapAction(let action):
            return reduceMapAction(action, state: &state)

        case .routeAction(let action):
            return reduceRouteAction(action, state: &state)

        case .placeListAction(let action):
            return reducePlaceListAction(action, state: &state)

        case .presentationAction(let action):
            return reducePresentationAction(action, state: &state)

        case .delegate(let action):
            return reduceDelegateAction(action, state: &state)
        }
    }
}
