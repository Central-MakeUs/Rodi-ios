//
//  HomeReducer.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct HomeReducer: Reducer {
    func reduce(_ state: inout HomeState, with action: HomeAction) -> Effect<HomeAction> {
        switch action {
            case .viewAction(let action):
                reduceViewAction(action, state: &state)

            case .runtimeAction(let action):
                reduceRuntimeAction(action, state: &state)

            case .mapAction(let action):
                reduceMapAction(action, state: &state)

            case .routeAction(let action):
                reduceRouteAction(action, state: &state)

            case .presentationAction(let action):
                reducePresentationAction(action, state: &state)

            case .delegate(let action):
                reduceDelegateAction(action, state: &state)
        }
    }
}
