//
//  OnboardingReducer2.swift
//  Rodi
//
//  Created by mac on 7/23/26.
//

import Foundation

struct OnboardingReducer2: Reducer {
    
    struct State {
        var isTermsAgreed = false
        var onboardingStep = OnboardingStep.entry
    }
    
    enum Action {
        case termAgreementTapped
    }
    
    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .termAgreementTapped:
            state.isTermsAgreed.toggle()
            return .none
        }
    }
    
    
}
