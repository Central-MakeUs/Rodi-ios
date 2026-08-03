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
