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
    let recentSearchRepository: RecentSearchRepository
    let recentLoginProviderStore: RecentLoginProviderStore

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

        recentSearchRepository = RecentSearchRepositoryImpl(
            remoteDataSource: RecentSearchRemoteDataSource(
                networkManager: authenticatedNetworkManager
            )
        )
    }
}
