//
//  AuthDependencyContainer.swift
//  Rodi
//

import Foundation

final class AuthDependencyContainer {
    static let shared = AuthDependencyContainer()

    let tokenStore: TokenStoring
    let unauthenticatedNetworkManager: NetworkManager
    let authenticatedNetworkManager: NetworkManager
    let authRepository: AuthRepository
    let memberRepository: MemberRepository
    let placeRepository: PlaceRepository
    let recentSearchRepository: RecentSearchRepository
    let recentLoginProviderStore: RecentLoginProviderStore

    private init() {
        let tokenStore = KeychainTokenStore()
        let recentLoginProviderStore = RecentLoginProviderStore()
        let unauthenticatedNetworkManager = NetworkManager()
        let tokenRefresher = AuthTokenRefreshCoordinator(
            networkManager: unauthenticatedNetworkManager,
            tokenStore: tokenStore
        )
        let authInterceptor = AuthInterceptor(
            tokenStore: tokenStore,
            tokenRefresher: tokenRefresher
        )

        self.tokenStore = tokenStore
        self.recentLoginProviderStore = recentLoginProviderStore
        self.unauthenticatedNetworkManager = unauthenticatedNetworkManager
        self.authenticatedNetworkManager = NetworkManager(authInterceptor: authInterceptor)
        self.authRepository = AuthRepositoryImpl(
            networkManager: unauthenticatedNetworkManager,
            tokenStore: tokenStore,
            tokenRefresher: tokenRefresher,
            recentLoginProviderStore: recentLoginProviderStore
        )
        self.memberRepository = MemberRepositoryImpl(
            networkManager: authenticatedNetworkManager
        )
        self.placeRepository = PlaceRepositoryImpl(
            publicNetworkManager: unauthenticatedNetworkManager,
            authenticatedNetworkManager: authenticatedNetworkManager
        )
        self.recentSearchRepository = RecentSearchRepositoryImpl(
            networkManager: authenticatedNetworkManager
        )
    }
}
