//
//  OnboardingStep.swift
//  Rodi
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case entry
    case terms
    case nickname
    case drivingExperience
    case optionalDrivingPreference
    case safety
    case locationPermission

    var progressCount: Int? {
        switch self {
        case .nickname:
            1
        case .drivingExperience:
            2
        case .optionalDrivingPreference:
            3
        case .entry, .terms, .safety, .locationPermission:
            nil
        }
    }

    var showsProgress: Bool {
        progressCount != nil
    }

    var showsBackNavigation: Bool {
        switch self {
        case .entry, .terms, .safety:
            false
        case .nickname, .drivingExperience, .optionalDrivingPreference, .locationPermission:
            true
        }
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}

/// 화면 전환의 의미를 분명히 하기 위한 별칭입니다.
/// 기존 UI 컴포넌트의 `OnboardingStep` API는 그대로 유지합니다.
typealias OnboardingRoute = OnboardingStep
