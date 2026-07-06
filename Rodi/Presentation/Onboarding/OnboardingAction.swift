//
//  OnboardingAction.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation

enum OnboardingAction {
    case navigation(NavigationAction)
    case terms(TermsAction)
    case safety(SafetyAction)
    case presentation(PresentationAction)

    enum NavigationAction {
        case backTapped
        case locationPermissionContinueTapped
    }

    enum TermsAction {
        case toggleAll
        case toggle(TermsAgreement)
        case open(TermsAgreement)
        case nextTapped
    }

    enum SafetyAction {
        case toggle(SafetyAgreement)
        case finishTapped
    }

    enum PresentationAction {
        case setTermsSheet(isPresented: Bool)
    }
}
