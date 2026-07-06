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

    private init() {
        let tokenStore = KeychainTokenStore()
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
        self.unauthenticatedNetworkManager = unauthenticatedNetworkManager
        self.authenticatedNetworkManager = NetworkManager(authInterceptor: authInterceptor)
        self.authRepository = AuthRepositoryImpl(
            networkManager: unauthenticatedNetworkManager,
            tokenStore: tokenStore,
            tokenRefresher: tokenRefresher
        )
    }
}
