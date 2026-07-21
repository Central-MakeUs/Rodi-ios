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

    func login(provider: AuthProvider, credential: String) async throws(NetworkError) -> AuthLoginResult {
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

        let result = try loginResponse.loginResult(provider: provider)
        if case .authenticated(let token) = result {
            saveAuthenticatedSession(token, provider: provider)
        }
        return result
    }

    func restore(provider: AuthProvider, credential: String) async throws(NetworkError) -> AuthToken {
        let trimmedCredential = credential.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCredential.isEmpty else {
            throw .apiError(code: "COMMON_400", message: "로그인 정보를 확인하지 못했어요.")
        }

        let response = try await networkManager.request(
            AuthTarget.restore(provider: provider, request: SocialLoginRequestDTO(credential: trimmedCredential)),
            as: ServerResponse<SocialLoginResponseDTO>.self
        )

        guard response.isSuccess, let restoreResponse = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }

        switch try restoreResponse.loginResult(provider: provider) {
        case .authenticated(let token):
            saveAuthenticatedSession(token, provider: provider)
            return token
        case .withdrawalPending:
            throw .apiError(code: "AUTH_RESTORE_PENDING", message: "계정 복구 상태를 확인하지 못했어요.")
        }
    }

    private func saveAuthenticatedSession(_ token: AuthToken, provider: AuthProvider) {
        tokenStore.update(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
        recentLoginProviderStore.save(provider)
        #if DEBUG
        RodiLogger.debug("AccessToken: \(RodiLogger.masked(token.accessToken))")
        RodiLogger.debug("RefreshToken: \(RodiLogger.masked(token.refreshToken))")
        #endif
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
