//
//  RootRoute.swift
//  Rodi
//

enum RootRoute: Equatable {
    case launching
    case onboarding(OnboardingLaunchContext)
    case mainTabs
}

enum OnboardingLaunchContext: Equatable {
    case normal
    case automaticLogin(SocialLoginProvider)
}
