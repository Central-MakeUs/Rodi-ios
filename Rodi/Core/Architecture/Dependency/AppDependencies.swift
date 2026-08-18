//
//  AppDependencies.swift
//  Rodi
//

import Foundation

@MainActor
final class AppDependencies {
    let snackbarService = SnackbarService()
    let tokenStore: TokenStoring
    let authRepository: AuthRepository
    let memberRepository: MemberRepository
    let placeRepository: PlaceRepository
    let practiceRepository: PracticeRepository
    let recentSearchRepository: RecentSearchRepository
    let reviewRepository: ReviewRepository
    let courseRepository: CourseRepository
    let recentLoginProviderStore: RecentLoginProviderStore
    let practiceMeasurementStore: PracticeMeasurementStoring
    let levelUpPresentationStore: LevelUpPresentationStoring

    init() {
        let tokenStore = KeychainTokenStore()

        let recentLoginProviderStore = RecentLoginProviderStore()

        let unauthenticatedNetworkManager = NetworkManager()

        let tokenRefresher = AuthTokenRefreshCoordinator(
            networkManager: unauthenticatedNetworkManager,
            tokenStore: tokenStore
        )

        let authenticatedNetworkManager = NetworkManager(
            authInterceptor: AuthInterceptor(
                tokenStore: tokenStore,
                tokenRefresher: tokenRefresher
            )
        )

        self.tokenStore = tokenStore
        self.recentLoginProviderStore = recentLoginProviderStore
        practiceMeasurementStore = PracticeMeasurementStore()
        levelUpPresentationStore = LevelUpPresentationStore(tokenStore: tokenStore)

        authRepository = AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSource(
                networkManager: unauthenticatedNetworkManager
            ),
            tokenStore: tokenStore,
            tokenRefresher: tokenRefresher,
            recentLoginProviderStore: recentLoginProviderStore
        )

        memberRepository = MemberRepositoryImpl(
            remoteDataSource: MemberRemoteDataSource(
                networkManager: authenticatedNetworkManager
            )
        )

        placeRepository = PlaceRepositoryImpl(
            remoteDataSource: PlaceRemoteDataSource(
                publicNetworkManager: unauthenticatedNetworkManager,
                authenticatedNetworkManager: authenticatedNetworkManager
            )
        )

        practiceRepository = PracticeRepositoryImpl(
            remoteDataSource: PracticeRemoteDataSource(
                networkManager: authenticatedNetworkManager
            )
        )

        reviewRepository = ReviewRepositoryImpl(
            remoteDataSource: ReviewRemoteDataSource(
                networkManager: authenticatedNetworkManager
            )
        )

        recentSearchRepository = RecentSearchRepositoryImpl(
            remoteDataSource: RecentSearchRemoteDataSource(
                networkManager: authenticatedNetworkManager
            )
        )

        courseRepository = CourseRepositoryImpl(
            remoteDataSource: CourseRemoteDataSource(
                networkManager: authenticatedNetworkManager
            )
        )
    }
}
