//
//  AuthRepositoryImpl.swift
//  Rodi
//

import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring
    private let tokenRefresher: AccessTokenRefreshing
    private let recentLoginProviderStore: RecentLoginProviderStore

    init(
        networkManager: NetworkManager,
        tokenStore: TokenStoring,
        tokenRefresher: AccessTokenRefreshing,
        recentLoginProviderStore: RecentLoginProviderStore
    ) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
        self.recentLoginProviderStore = recentLoginProviderStore
    }

    func login(provider: AuthProvider, credential: String) async throws(NetworkError) -> AuthToken {
        let trimmedCredential = credential.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCredential.isEmpty else {
            throw .apiError(code: "COMMON_400", message: "로그인 정보를 확인하지 못했어요.")
        }

        let request = SocialLoginRequestDTO(credential: trimmedCredential)
        let response = try await networkManager.request(
            AuthTarget.login(provider: provider, request: request),
            as: ServerResponse<SocialLoginResponseDTO>.self
        )

        guard response.isSuccess, let loginResponse = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }

        let token = try loginResponse.validatedToken()

        tokenStore.update(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
        recentLoginProviderStore.save(provider)
        #if DEBUG
        RodiLogger.debug("AccessToken: \(RodiLogger.masked(token.accessToken))")
        RodiLogger.debug("RefreshToken: \(RodiLogger.masked(token.refreshToken))")
        #endif
        return token
    }

    func refreshToken() async throws(NetworkError) -> AuthToken {
        guard let refreshed = try await tokenRefresher.refreshAccessToken() else {
            throw .refreshFailGoRoot
        }

        return AuthToken(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken,
            isNewMember: false,
            nickname: nil
        )
    }

    func logout() async throws(NetworkError) {
        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            tokenStore.clear()
            return
        }

        let request = LogoutRequestDTO(refreshToken: refreshToken)
        _ = try await networkManager.request(
            AuthTarget.logout(request: request),
            as: ServerResponse<EmptyResponse>.self
        )
        tokenStore.clear()
    }

    func clearSession() {
        tokenStore.clear()
    }
}
