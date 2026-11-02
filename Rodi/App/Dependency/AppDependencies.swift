//
//  AppDependencies.swift
//  Rodi
//

import Foundation

/// 앱 전체의 Data 구현체를 Domain 계약으로 조립하는 composition root다.
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
    let drivePracticeService: DrivePracticeService
    let levelUpPresentationStore: LevelUpPresentationStore

    init() {
        let backend = AppBackendConfiguration.current
        let tokenStore = KeychainTokenStore(service: backend.tokenService)
        DevelopmentServerMigration.runIfNeeded(
            configuration: backend,
            legacyTokenStore: KeychainTokenStore(service: backend.bundleIdentifier),
            tokenStore: tokenStore,
            clearServerState: { DevelopmentServerMigration.clearServerState() }
        )
        let recentLoginProviderStore = RecentLoginProviderStore()
        let drivePracticeService = DrivePracticeService.shared
        let unauthenticatedNetworkManager = NetworkManager()
        let authRemoteDataSource = AuthRemoteDataSource(
            networkManager: unauthenticatedNetworkManager
        )
        let tokenRefresher = AuthTokenRefreshCoordinator(
            remoteDataSource: authRemoteDataSource,
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
        self.drivePracticeService = drivePracticeService
        levelUpPresentationStore = LevelUpPresentationStore(tokenStore: tokenStore)

        authRepository = AuthRepositoryImpl(
            remoteDataSource: authRemoteDataSource,
            tokenStore: tokenStore,
            tokenRefresher: tokenRefresher,
            recentLoginProviderStore: recentLoginProviderStore
        )

        memberRepository = MemberRepositoryImpl(
            remoteDataSource: MemberRemoteDataSource(networkManager: authenticatedNetworkManager)
        )

        placeRepository = PlaceRepositoryImpl(
            remoteDataSource: PlaceRemoteDataSource(
                publicNetworkManager: unauthenticatedNetworkManager,
                authenticatedNetworkManager: authenticatedNetworkManager
            )
        )

        practiceRepository = PracticeRepositoryImpl(
            remoteDataSource: PracticeRemoteDataSource(networkManager: authenticatedNetworkManager)
        )

        reviewRepository = ReviewRepositoryImpl(
            remoteDataSource: ReviewRemoteDataSource(networkManager: authenticatedNetworkManager)
        )

        recentSearchRepository = RecentSearchRepositoryImpl(
            remoteDataSource: RecentSearchRemoteDataSource(networkManager: authenticatedNetworkManager)
        )

        courseRepository = CourseRepositoryImpl(
            remoteDataSource: CourseRemoteDataSource(networkManager: authenticatedNetworkManager)
        )

        drivePracticeService.configure(
            practiceRepository: practiceRepository,
            measurementStore: practiceMeasurementStore
        )
    }
}
