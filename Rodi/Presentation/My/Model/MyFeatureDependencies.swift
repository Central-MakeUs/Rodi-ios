//
//  MyFeatureDependencies.swift
//  Rodi
//

import Foundation

/// My feature가 실제로 사용하는 의존성만 묶는다.
/// App 조립 객체를 View 계층 전체로 전달하지 않기 위한 feature 경계다.
struct MyFeatureDependencies {
    let authRepository: AuthRepository
    let memberRepository: MemberRepository
    let placeRepository: PlaceRepository
    let practiceRepository: PracticeRepository
    let reviewRepository: ReviewRepository
    let courseRepository: CourseRepository
    let recentLoginProviderStore: RecentLoginProviderStore
    let levelUpPresentationStore: LevelUpPresentationStore
    let socialSessionService: SocialSessionService

    init(appDependencies: AppDependencies) {
        authRepository = appDependencies.authRepository
        memberRepository = appDependencies.memberRepository
        placeRepository = appDependencies.placeRepository
        practiceRepository = appDependencies.practiceRepository
        reviewRepository = appDependencies.reviewRepository
        courseRepository = appDependencies.courseRepository
        recentLoginProviderStore = appDependencies.recentLoginProviderStore
        levelUpPresentationStore = appDependencies.levelUpPresentationStore
        socialSessionService = SocialSessionService()
    }

    var destinations: MyDestinationDependencies {
        .init(
            memberRepository: memberRepository,
            placeRepository: placeRepository,
            practiceRepository: practiceRepository,
            reviewRepository: reviewRepository,
            courseRepository: courseRepository
        )
    }
}

struct MyDestinationDependencies {
    let memberRepository: MemberRepository
    let placeRepository: PlaceRepository
    let practiceRepository: PracticeRepository
    let reviewRepository: ReviewRepository
    let courseRepository: CourseRepository
}
