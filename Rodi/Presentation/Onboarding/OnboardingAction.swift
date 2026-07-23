//
//  OnboardingAction.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation

enum OnboardingAction {
    case navigation(NavigationAction)
    case entry(EntryAction)
    case terms(TermsAction)
    case nickname(NicknameAction)
    case drivingExperience(DrivingExperienceAction)
    case optionalDrivingPreference(OptionalDrivingPreferenceAction)
    case safety(SafetyAction)
    case presentation(PresentationAction)

    enum NavigationAction {
        case backTapped
        case locationPermissionContinueTapped
    }

    enum EntryAction {
        case browseTapped
        case appleLoginTapped
        case authStarted(AuthProvider)
        case authCancelled(AuthProvider)
        case authSucceeded(AuthProvider, isNewMember: Bool, nickname: String?)
        case authFailed(AuthProvider, String)
        case withdrawalRecoveryRequired(AuthWithdrawalRecovery)
        case withdrawalRestoreStarted
        case withdrawalRestoreLocked(rejoinAvailableAt: Date?)
        case dismissWithdrawalDialog
        case dismissLoginAlert
    }

    enum TermsAction {
        case toggleAll
        case toggle(TermsAgreement)
        case open(TermsAgreement)
        case nextTapped
    }

    enum NicknameAction {
        case nextTapped
    }

    enum DrivingExperienceAction {
        case selectLicenseDrivingPeriod(LicenseDrivingPeriod)
        case selectRecentDrivingFrequency(RecentDrivingFrequency)
        case toggleRoadDrivingExperience(RoadDrivingExperience)
        case selectSoloDrivingRange(SoloDrivingRange)
        case selectSoloParkingLevel(SoloParkingLevel)
        case nextTapped
    }

    enum OptionalDrivingPreferenceAction {
        case togglePracticeSituation(PracticeSituation)
        case selectVehicleType(VehicleType)
        case skipTapped
        case nextTapped(drivingGoal: String)
        case analysisFinished
        case analysisFailed(String)
        case analysisCompletionConfirmed
    }

    enum SafetyAction {
        case toggle(SafetyAgreement)
        case finishTapped
    }

    enum PresentationAction {
        case setTermsSheet(isPresented: Bool)
        case showSnackbar(String)
        case dismissSnackbar
    }
}
