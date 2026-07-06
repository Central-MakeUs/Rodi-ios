//
//  OnboardingReducer+.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

extension OnboardingReducer {
    func reduceNavigationAction(_ action: OnboardingAction.NavigationAction, state: inout OnboardingState) {
        switch action {
        case .backTapped:
            if let previous = state.step.previous {
                state.step = previous
            }

        case .locationPermissionContinueTapped:
            state.step = .terms
        }
    }

    func reduceTermsAction(_ action: OnboardingAction.TermsAction, state: inout OnboardingState) {
        switch action {
            case .toggleAll:
                if state.isAllTermsAgreed {
                    state.agreedTerms.removeAll()
                } else {
                    state.agreedTerms = Set(TermsAgreement.allCases)
                }

            case .toggle(let terms):
                if state.agreedTerms.contains(terms) {
                    state.agreedTerms.remove(terms)
                } else {
                    state.agreedTerms.insert(terms)
                }

            case .open(let terms):
                state.selectedTermsPage = terms

            case .nextTapped:
                guard state.isAllTermsAgreed else { return }
                state.step = .safety
        }
    }

    func reduceSafetyAction(_ action: OnboardingAction.SafetyAction, state: inout OnboardingState) {
        switch action {
            case .toggle(let item):
                if state.agreedSafetyItems.contains(item) {
                    state.agreedSafetyItems.remove(item)
                } else {
                    state.agreedSafetyItems.insert(item)
                }

            case .finishTapped:
                guard state.isAllSafetyAgreed else { return }
                state.didComplete = true
        }
    }

    func reducePresentationAction(_ action: OnboardingAction.PresentationAction, state: inout OnboardingState) {
        switch action {
            case .setTermsSheet(let isPresented):
                if !isPresented {
                    state.selectedTermsPage = nil
                }
        }
    }
}
