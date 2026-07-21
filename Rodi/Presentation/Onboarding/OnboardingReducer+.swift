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
                state.isBrowseUser = true
                state.loginProvider = nil
                state.step = .terms

            case .appleLoginTapped:
                state.isAuthenticating = true

            case .authStarted:
                state.isAuthenticating = true
                state.loginAlertMessage = nil
                state.withdrawalDialog = nil

            case .authSucceeded(let provider, let isNewMember, let nickname):
                state.isAuthenticating = false
                state.loginAlertMessage = nil
                state.withdrawalDialog = nil
                state.isBrowseUser = false

                if isNewMember {
                    state.loginProvider = provider
                    state.nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    state.step = .terms
                } else {
                    state.didComplete = true
                }

            case .authFailed(_, let message):
                state.isAuthenticating = false
                state.loginAlertMessage = message

            case .withdrawalRecoveryRequired(let recovery):
                state.isAuthenticating = false
                state.loginAlertMessage = nil
                state.withdrawalDialog = .restore(recovery)

            case .withdrawalRestoreStarted:
                state.isAuthenticating = true
                state.loginAlertMessage = nil
                state.withdrawalDialog = nil

            case .withdrawalRestoreLocked(let rejoinAvailableAt):
                state.isAuthenticating = false
                state.loginAlertMessage = nil
                state.withdrawalDialog = .rejoinLocked(rejoinAvailableAt: rejoinAvailableAt)

            case .dismissWithdrawalDialog:
                state.withdrawalDialog = nil

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
                state.step = state.isBrowseUser ? .safety : .nickname
        }
    }

    func reduceNicknameAction(_ action: OnboardingAction.NicknameAction, state: inout OnboardingState) {
        switch action {
            case .nextTapped:
                guard state.canProceedFromNickname else { return }
                state.step = .drivingExperience
        }
    }

    func reduceDrivingExperienceAction(_ action: OnboardingAction.DrivingExperienceAction, state: inout OnboardingState) {
        switch action {
            case .selectLicenseDrivingPeriod(let period):
                state.licenseDrivingPeriod = period

            case .selectRecentDrivingFrequency(let frequency):
                state.recentDrivingFrequency = frequency

            case .toggleRoadDrivingExperience(let experience):
                if experience == .none {
                    if state.selectedRoadDrivingExperiences == [.none] {
                        state.selectedRoadDrivingExperiences.removeAll()
                    } else {
                        state.selectedRoadDrivingExperiences = [.none]
                    }
                } else if let index = state.selectedRoadDrivingExperiences.firstIndex(of: experience) {
                    state.selectedRoadDrivingExperiences.remove(at: index)
                } else {
                    state.selectedRoadDrivingExperiences.removeAll { $0 == .none }
                    state.selectedRoadDrivingExperiences.append(experience)
                }

                if !state.selectedRoadDrivingExperiences.contains(.soloPractice) {
                    state.soloDrivingRange = nil
                    state.soloParkingLevel = nil
                }

            case .selectSoloDrivingRange(let range):
                state.soloDrivingRange = range

            case .selectSoloParkingLevel(let level):
                state.soloParkingLevel = level

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

            case .skipTapped:
                state.drivingGoal = ""
                startOnboardingAnalysis(state: &state)

            case .nextTapped(let drivingGoal):
                guard state.canProceedFromOptionalDrivingPreference else { return }
                state.drivingGoal = drivingGoal
                startOnboardingAnalysis(state: &state)

            case .analysisFinished:
                state.isOnboardingAnalysisPresented = false
                state.isOnboardingAnalysisCompletionPresented = true

            case .analysisCompletionConfirmed:
                state.isOnboardingAnalysisCompletionPresented = false
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

    private func startOnboardingAnalysis(state: inout OnboardingState) {
        guard !state.isOnboardingAnalysisPresented,
              let submission = state.memberOnboardingSubmission
        else {
            return
        }

        state.onboardingAnalysis = MemberOnboardingLevelPolicy.analyze(submission)
        state.isOnboardingAnalysisPresented = true
    }
}
