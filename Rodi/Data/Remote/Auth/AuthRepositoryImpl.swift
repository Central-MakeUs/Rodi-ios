//
//  AuthRepositoryImpl.swift
//  Rodi
//

import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring
    private let tokenRefresher: AccessTokenRefreshing

    init(
        networkManager: NetworkManager,
        tokenStore: TokenStoring,
        tokenRefresher: AccessTokenRefreshing
    ) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
    }

    func login(provider: AuthProvider, credential: String) async throws(NetworkError) -> AuthToken {
        let trimmedCredential = credential.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCredential.isEmpty else {
            throw .apiError(code: "COMMON_400", message: "로그인 정보를 확인하지 못했어요.")
        }

        let request = SocialLoginRequestDTO(credential: trimmedCredential)
        let response = try await networkManager.request(
            AuthTarget.login(provider: provider, request: request),
            as: ServerResponse<AuthTokenDTO>.self
        )

        guard response.isSuccess, let token = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }

        tokenStore.update(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
        #if DEBUG
        RodiLogger.debug("AccessToken: \(token.accessToken)")
        RodiLogger.debug("RefreshToken: \(token.refreshToken)")
        #endif
        return token.domain
    }

    func refreshToken() async throws(NetworkError) -> AuthToken {
        guard let refreshed = try await tokenRefresher.refreshAccessToken() else {
            throw .refreshFailGoRoot
        }

        return AuthToken(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken,
            isNewMember: false
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
