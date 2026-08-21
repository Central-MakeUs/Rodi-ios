//
//  OnboardingFeatureDependencies.swift
//  Rodi
//

struct OnboardingFeatureDependencies {
    let authRepository: AuthRepository
    let recentLoginProviderStore: RecentLoginProviderStore
    let memberRepository: MemberRepository

    init(appDependencies: AppDependencies) {
        authRepository = appDependencies.authRepository
        recentLoginProviderStore = appDependencies.recentLoginProviderStore
        memberRepository = appDependencies.memberRepository
    }
}
