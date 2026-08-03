//
//  AuthRepositoryImpl.swift
//  Rodi
//

import Foundation

// Auth remote DTO를 앱의 인증 계약으로 변환한다.

final class AuthRepositoryImpl: AuthRepository {
    private let remoteDataSource: AuthRemoteDataSource
    private let tokenStore: TokenStoring
    private let tokenRefresher: AccessTokenRefreshing
    private let recentLoginProviderStore: RecentLoginProviderStore

    init(
        remoteDataSource: AuthRemoteDataSource,
        tokenStore: TokenStoring,
        tokenRefresher: AccessTokenRefreshing,
        recentLoginProviderStore: RecentLoginProviderStore
    ) {
        self.remoteDataSource = remoteDataSource
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
        self.recentLoginProviderStore = recentLoginProviderStore
    }

    func login(
        provider: SocialLoginProvider,
        credential: String
    ) async throws(
        NetworkError
    ) -> AuthLoginResult {
        let trimmedCredential = credential.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedCredential.isEmpty else {
            throw .apiError(
                code: "COMMON_400",
                message: "로그인 정보를 확인하지 못했어요."
            )
        }
        
        let request = SocialLoginRequestDTO(
            credential: trimmedCredential
        )
        let loginResponse = try await remoteDataSource.login(
            provider: provider,
            request: request
        )
        
        let result = try loginResponse.loginResult(
            provider: provider
        )
        if case .authenticated(
            let token
        ) = result {
            saveAuthenticatedSession(
                token,
                provider: provider
            )
        }
        return result
    }
    
    func restore(
        provider: SocialLoginProvider,
        credential: String
    ) async throws(
        NetworkError
    ) -> AuthToken {
        let trimmedCredential = credential.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedCredential.isEmpty else {
            throw .apiError(
                code: "COMMON_400",
                message: "로그인 정보를 확인하지 못했어요."
            )
        }
        
        let restoreResponse = try await remoteDataSource.restore(
            provider: provider,
            request: SocialLoginRequestDTO(
                credential: trimmedCredential
            )
        )
        
        switch try restoreResponse
            .loginResult(
                provider: provider
            ) {
        case .authenticated(
            let token
        ):
            saveAuthenticatedSession(
                token,
                provider: provider
            )
            return token
        case .withdrawalPending:
            throw .apiError(
                code: "AUTH_RESTORE_PENDING",
                message: "계정 복구 상태를 확인하지 못했어요."
            )
        }
    }
    
    private func saveAuthenticatedSession(
        _ token: AuthToken,
        provider: SocialLoginProvider
    ) {
        tokenStore
            .update(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken
            )
        recentLoginProviderStore
            .save(
                provider
            )
#if DEBUG
        RodiLogger
            .debug(
                "Swagger Access Token: \(token.accessToken)"
            )
#endif
    }
    
    func refreshToken() async throws(
        NetworkError
    ) -> AuthToken {
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
    
    func logout() async throws(
        NetworkError
    ) {
        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            tokenStore
                .clear()
            return
        }
        
        let request = LogoutRequestDTO(
            refreshToken: refreshToken
        )
        try await remoteDataSource
            .logout(
                request
            )
        tokenStore
            .clear()
    }
    
    func clearSession() {
        tokenStore
            .clear()
    }
}
