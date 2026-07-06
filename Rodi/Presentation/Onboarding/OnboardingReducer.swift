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
            
            case .entry(let action):
                reduceEntryAction(action, state: &state)
            
            case .terms(let action):
                reduceTermsAction(action, state: &state)
            
            case .nickname(let action):
                reduceNicknameAction(action, state: &state)
            
            case .drivingExperience(let action):
                reduceDrivingExperienceAction(action, state: &state)
            
            case .optionalDrivingPreference(let action):
                reduceOptionalDrivingPreferenceAction(action, state: &state)
            
            case .safety(let action):
                reduceSafetyAction(action, state: &state)
            
            case .presentation(let action):
                reducePresentationAction(action, state: &state)
        }

        return .none
    }
}
