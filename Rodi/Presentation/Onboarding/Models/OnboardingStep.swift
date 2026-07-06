//
//  OnboardingStep.swift
//  Rodi
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case locationPermission
    case terms
    case safety

    var progressCount: Int? {
        switch self {
        case .locationPermission:
            1
        case .terms:
            2
        case .safety:
            3
        }
    }

    var showsProgress: Bool {
        progressCount != nil
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}
