//
//  OnboardingState.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct OnboardingState {
    var step: OnboardingStep = .entry
    var agreedTerms: Set<TermsAgreement> = []
    var agreedSafetyItems: Set<SafetyAgreement> = []
    var selectedTermsPage: TermsAgreement?
    var didComplete = false
    var isAuthenticating = false
    var loginAlertMessage: String?
    var isKakaoLoginMethodDialogPresented = false
    var isKakaoTalkFallbackAlertPresented = false
    // TODO: 서버에서 내려주는 유효 닉네임으로 대체
    var nickname = "차분한 고래"
    var licenseDrivingPeriod: LicenseDrivingPeriod?
    var recentDrivingFrequency: RecentDrivingFrequency?
    var roadDrivingExperience: RoadDrivingExperience?
    var selectedPracticeSituations: [PracticeSituation] = []
    var vehicleType: VehicleType?
    var drivingGoal = ""

    var isAllTermsAgreed: Bool {
        agreedTerms.count == TermsAgreement.allCases.count
    }

    var isAllSafetyAgreed: Bool {
        agreedSafetyItems.count == SafetyAgreement.allCases.count
    }

    var canProceedFromDrivingExperience: Bool {
        licenseDrivingPeriod != nil
            && recentDrivingFrequency != nil
            && roadDrivingExperience != nil
    }

    var canProceedFromOptionalDrivingPreference: Bool {
        !selectedPracticeSituations.isEmpty && vehicleType != nil
    }
}
