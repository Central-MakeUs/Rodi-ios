//
//  OnboardingState.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct OnboardingState {
    var step: OnboardingStep = .locationPermission
    var agreedTerms: Set<TermsAgreement> = []
    var agreedSafetyItems: Set<SafetyAgreement> = []
    var selectedTermsPage: TermsAgreement?
    var didComplete = false

    var isAllTermsAgreed: Bool {
        agreedTerms.count == TermsAgreement.allCases.count
    }

    var isAllSafetyAgreed: Bool {
        agreedSafetyItems.count == SafetyAgreement.allCases.count
    }
}
