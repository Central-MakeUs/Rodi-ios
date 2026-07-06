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
            state.didComplete = true
        }
    }

    func reduceEntryAction(_ action: OnboardingAction.EntryAction, state: inout OnboardingState) {
        switch action {
            case .browseTapped:
                state.didComplete = true

            case .appleLoginTapped:
                state.isAuthenticating = true

            case .kakaoLoginTapped:
                state.isKakaoLoginMethodDialogPresented = true

            case .kakaoTalkUnavailable:
                state.isKakaoTalkFallbackAlertPresented = true

            case .kakaoMethodDialogDismissed:
                state.isKakaoLoginMethodDialogPresented = false

            case .kakaoTalkFallbackAlertDismissed:
                state.isKakaoTalkFallbackAlertPresented = false

            case .kakaoLoginMethodSelected:
                state.isKakaoLoginMethodDialogPresented = false
                state.isKakaoTalkFallbackAlertPresented = false
                state.isAuthenticating = true

            case .authStarted:
                state.isAuthenticating = true
                state.loginAlertMessage = nil

            case .authSucceeded(_, let isNewMember):
                state.isAuthenticating = false
                state.loginAlertMessage = nil
                if isNewMember {
                    state.step = .terms
                } else {
                    state.didComplete = true
                }

            case .authFailed(_, let message):
                state.isAuthenticating = false
                state.loginAlertMessage = message

            case .dismissLoginAlert:
                state.loginAlertMessage = nil
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
                state.step = .nickname
        }
    }

    func reduceNicknameAction(_ action: OnboardingAction.NicknameAction, state: inout OnboardingState) {
        switch action {
            case .nextTapped:
                state.step = .drivingExperience
        }
    }

    func reduceDrivingExperienceAction(_ action: OnboardingAction.DrivingExperienceAction, state: inout OnboardingState) {
        switch action {
            case .selectLicenseDrivingPeriod(let period):
                state.licenseDrivingPeriod = period

            case .selectRecentDrivingFrequency(let frequency):
                state.recentDrivingFrequency = frequency

            case .selectRoadDrivingExperience(let experience):
                state.roadDrivingExperience = experience

            case .nextTapped:
                guard state.canProceedFromDrivingExperience else { return }
                state.step = .optionalDrivingPreference
        }
    }

    func reduceOptionalDrivingPreferenceAction(_ action: OnboardingAction.OptionalDrivingPreferenceAction, state: inout OnboardingState) {
        switch action {
            case .togglePracticeSituation(let situation):
                if let index = state.selectedPracticeSituations.firstIndex(of: situation) {
                    state.selectedPracticeSituations.remove(at: index)
                } else if state.selectedPracticeSituations.count < 3 {
                    state.selectedPracticeSituations.append(situation)
                }

            case .selectVehicleType(let vehicleType):
                state.vehicleType = vehicleType

            case .updateGoal(let goal):
                state.drivingGoal = goal

            case .skipTapped:
                state.step = .safety

            case .nextTapped:
                guard state.canProceedFromOptionalDrivingPreference else { return }
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
                state.step = .locationPermission
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
