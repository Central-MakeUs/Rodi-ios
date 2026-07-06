//
//  OnboardingReducer.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct OnboardingReducer: Reducer {
    func reduce(_ state: inout OnboardingState, with action: OnboardingAction) -> Effect<OnboardingAction> {
        switch action {
            case .navigation(let action):
                reduceNavigationAction(action, state: &state)
            
            case .terms(let action):
                reduceTermsAction(action, state: &state)
            
            case .safety(let action):
                reduceSafetyAction(action, state: &state)
            
            case .presentation(let action):
                reducePresentationAction(action, state: &state)
        }

        return .none
    }
}
