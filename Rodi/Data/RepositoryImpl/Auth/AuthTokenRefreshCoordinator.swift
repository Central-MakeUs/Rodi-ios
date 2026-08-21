//
//  AuthTokenRefreshCoordinator.swift
//  Rodi
//

import Foundation

@MainActor
final class AuthTokenRefreshCoordinator: AccessTokenRefreshing {
    private typealias RefreshTask = Task<TokenRefreshResult?, Error>

    private let remoteDataSource: AuthRemoteDataSource
    private let tokenStore: TokenStoring
    private var refreshTask: RefreshTask?
    private var refreshTaskID: UUID?
    
    init(
        remoteDataSource: AuthRemoteDataSource,
        tokenStore: TokenStoring
    ) {
        self.remoteDataSource = remoteDataSource
        self.tokenStore = tokenStore
    }
    
    func refreshAccessToken() async throws(
        NetworkError
    ) -> TokenRefreshResult? {
        let task: RefreshTask
        let taskID: UUID

        if let refreshTask, let refreshTaskID {
            task = refreshTask
            taskID = refreshTaskID
        } else {
            taskID = UUID()
            task = makeRefreshTask()
            refreshTask = task
            refreshTaskID = taskID
        }

        do {
            let result = try await resolve(task)
            finishRefreshTask(id: taskID)
            return result
        } catch let error {
            finishRefreshTask(id: taskID)
            if error.invalidatesAuthSession {
                tokenStore.clear()
            }
            throw error
        }
    }

    /// 여러 인증 요청이 하나의 refresh 작업을 공유해야 하므로, 이 Task의 수명은
    /// 개별 호출자가 아니라 coordinator가 소유한다.
    private func makeRefreshTask() -> RefreshTask {
        Task { @MainActor [remoteDataSource, tokenStore] () throws -> TokenRefreshResult? in
            guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
                throw NetworkError.refreshFailGoRoot
            }

            let token = try await remoteDataSource.refresh(
                AuthMapper.tokenRefreshRequest(refreshToken: refreshToken)
            )
            tokenStore.update(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken
            )

            return TokenRefreshResult(
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                isOnboarded: token.isOnboarded,
                isCourseTutorialCompleted: token.isCourseTutorialCompleted
            )
        }
    }

    private func finishRefreshTask(id: UUID) {
        guard refreshTaskID == id else { return }
        refreshTask = nil
        refreshTaskID = nil
    }

    private func resolve(
        _ task: RefreshTask
    ) async throws(
        NetworkError
    ) -> TokenRefreshResult? {
        do {
            return try await task.value
        } catch let error as NetworkError {
            throw error
        } catch {
            throw .unknown(
                errorCode: error.localizedDescription
            )
        }
    }
}
