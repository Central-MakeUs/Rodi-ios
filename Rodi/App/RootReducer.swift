//
//  RootReducer.swift
//  Rodi
//
//  Created by mac on 7/28/26.
//

import Foundation

@MainActor
struct RootReducer: Reducer {

    struct State {
        var pendingUpdate: AppVersionUpdate?
        var hasCheckedAppVersion = false
        var isRestoringSession = false
    }

    enum Action {
        case launched
        case sceneBecameActive
        case appVersionCheckCompleted(AppVersionUpdate?)
        case appVersionUpdateDismissed
        case sessionRestoreCompleted(SessionRestoreResult)
    }

    enum SessionRestoreResult {
        case refreshed
        case invalidated
        case deferred(String)
    }

    private enum EffectID {
        case appVersionCheck
        case sessionRestore
    }

    private let tokenStore: TokenStoring = AuthDependencyContainer.shared.tokenStore
    private let authRepository: AuthRepository = AuthDependencyContainer.shared.authRepository
}

// MARK: Core Logic
extension RootReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .launched:
            return checkAppVersionIfNeeded(state: &state)

        case .sceneBecameActive:
            return restoreSessionIfNeeded(state: &state)

        case .appVersionCheckCompleted(let update):
            state.pendingUpdate = update

        case .appVersionUpdateDismissed:
            state.pendingUpdate = nil

        case .sessionRestoreCompleted(let result):
            state.isRestoringSession = false

            switch result {
            case .refreshed:
                RodiLogger.info("Auth session restored")
            case .invalidated:
                authRepository.clearSession()
                RodiLogger.info("Auth session cleared after refresh rejection")
            case .deferred(let message):
                RodiLogger.warning("Auth session restore deferred: \(message)")
            }
        }

        return .none
    }

    private func checkAppVersionIfNeeded(state: inout State) -> Effect<Action> {
        guard !state.hasCheckedAppVersion else { return .none }

        state.hasCheckedAppVersion = true

        return .run { send in
            let update = await AppVersionUpdateChecker.checkForOptionalUpdate()
            await send(.appVersionCheckCompleted(update))
        }
        .cancelTask(id: EffectID.appVersionCheck)
    }

    private func restoreSessionIfNeeded(state: inout State) -> Effect<Action> {
        guard !state.isRestoringSession,
              let refreshToken = tokenStore.refreshToken,
              !refreshToken.isEmpty
        else {
            return .none
        }

        let needsRefresh = tokenStore.accessToken.map { AccessTokenExpiry.needsRefresh($0) } ?? true
        guard needsRefresh else { return .none }

        state.isRestoringSession = true
        return .run { send in


            do {
                _ = try await authRepository.refreshToken()
                await send(.sessionRestoreCompleted(.refreshed))
            } catch let error as NetworkError {
                if error.invalidatesAuthSession {
                    await send(.sessionRestoreCompleted(.invalidated))
                } else {
                    await send(.sessionRestoreCompleted(.deferred(error.localizedDescription)))
                }
            } catch {
                await send(.sessionRestoreCompleted(.deferred(error.localizedDescription)))
            }
        }
        .cancelTask(id: EffectID.sessionRestore)
    }
}
