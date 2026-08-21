//
//  MainTabFeatureDependencies.swift
//  Rodi
//

struct MainTabFeatureDependencies {
    let tokenStore: TokenStoring
    let memberRepository: MemberRepository
    let courseRepository: CourseRepository
    let home: HomeFeatureDependencies
    let my: MyFeatureDependencies

    init(appDependencies: AppDependencies) {
        tokenStore = appDependencies.tokenStore
        memberRepository = appDependencies.memberRepository
        courseRepository = appDependencies.courseRepository
        home = .init(appDependencies: appDependencies)
        my = .init(appDependencies: appDependencies)
    }
}
