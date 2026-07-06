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
        case kakaoLoginTapped
        case kakaoTalkUnavailable
        case kakaoMethodDialogDismissed
        case kakaoTalkFallbackAlertDismissed
        case kakaoLoginMethodSelected(KakaoLoginMethod)
        case authStarted(AuthProvider)
        case authSucceeded(AuthProvider, isNewMember: Bool)
        case authFailed(AuthProvider, String)
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
        case selectRoadDrivingExperience(RoadDrivingExperience)
        case nextTapped
    }

    enum OptionalDrivingPreferenceAction {
        case togglePracticeSituation(PracticeSituation)
        case selectVehicleType(VehicleType)
        case updateGoal(String)
        case skipTapped
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
