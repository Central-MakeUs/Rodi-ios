//
//  AuthTokenRefreshCoordinator.swift
//  Rodi
//

import Foundation

@MainActor
final class AuthTokenRefreshCoordinator: AccessTokenRefreshing {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring
    private var refreshTask: Task<TokenRefreshResult?, Error>?

    init(networkManager: NetworkManager, tokenStore: TokenStoring) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    func refreshAccessToken() async throws(NetworkError) -> TokenRefreshResult? {
        if let refreshTask {
            return try await resolve(refreshTask)
        }

        let task = Task { [networkManager, tokenStore] () throws -> TokenRefreshResult? in
            guard let refreshToken = await MainActor.run(body: { tokenStore.refreshToken }),
                  !refreshToken.isEmpty else {
                throw NetworkError.refreshFailGoRoot
            }

            let request = TokenRefreshRequestDTO(refreshToken: refreshToken)
            let response = try await networkManager.request(
                AuthTarget.refresh(request: request),
                as: ServerResponse<AuthTokenDTO>.self
            )

            guard response.isSuccess, let token = response.data else {
                throw NetworkError.apiError(code: response.code, message: response.message)
            }

            await MainActor.run {
                tokenStore.update(
                    accessToken: token.accessToken,
                    refreshToken: token.refreshToken
                )
            }
            return token.refreshResult
        }

        refreshTask = task
        defer { refreshTask = nil }

        do {
            return try await resolve(task)
        } catch let error {
            if error.invalidatesAuthSession {
                tokenStore.clear()
            }
            throw error
        }
    }

    private func resolve(_ task: Task<TokenRefreshResult?, Error>) async throws(NetworkError) -> TokenRefreshResult? {
        do {
            return try await task.value
        } catch let error as NetworkError {
            throw error
        } catch {
            throw .unknown(errorCode: error.localizedDescription)
        }
    }
}
