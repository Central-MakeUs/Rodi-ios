//
//  OnboardingRoute.swift
//  Rodi
//

import Foundation

enum OnboardingRoute: Int, Route {
    case terms
    case nickname
    case drivingExperience
    case optionalDrivingPreference
    case safety
    case locationPermission

    var id: String {
        switch self {
        case .terms: "onboarding.terms"
        case .nickname: "onboarding.nickname"
        case .drivingExperience: "onboarding.drivingExperience"
        case .optionalDrivingPreference: "onboarding.optionalDrivingPreference"
        case .safety: "onboarding.safety"
        case .locationPermission: "onboarding.locationPermission"
        }
    }
}
