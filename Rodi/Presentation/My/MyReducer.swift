//
//  MyReducer.swift
//  Rodi
//

import Foundation
import KakaoSDKUser

struct MyReducer: Reducer {
    struct State {
        var profile: MemberProfile?
        var isLoadingProfile = false
        var hasCompletedInitialLoad = false
        var profileErrorMessage: String?
        var profileRequestID = 0
        var networkStatus: NetworkConnectionMonitor.Status = .checking
        var shouldRetryProfileAfterRecovery = false
        var hasAutomaticallyRetriedAfterRecovery = false
        var snackbarMessage: String?
        var didEndSessionRequestID = 0
        var hasTrackedMyOpen = false
    }

    enum Action {
        case appeared
        case retryProfileTapped
        case networkStatusChanged(NetworkConnectionMonitor.Status)
        case profileLoaded(ProfileLoadResult, requestID: Int)
        case drivingGoalUpdated(MemberProfile)
        case logoutConfirmed
        case withdrawalConfirmed
        case sessionEnded(SessionEndReason)
        case snackbarDismissed(String)
    }

    enum ProfileLoadResult {
        case success(MemberProfile)
        case failure(String)
    }

    enum SessionEndReason {
        case logout
        case withdrawal
    }

    private enum EffectID {
        case profile
        case session
        case snackbar
    }

    private let authRepository: AuthRepository
    private let memberRepository: MemberRepository
    private let recentLoginProviderStore: RecentLoginProviderStore

    init(
        authRepository: AuthRepository,
        memberRepository: MemberRepository,
        recentLoginProviderStore: RecentLoginProviderStore
    ) {
        self.authRepository = authRepository
        self.memberRepository = memberRepository
        self.recentLoginProviderStore = recentLoginProviderStore
    }

}

// MARK: Core Logic
extension MyReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            if !state.hasTrackedMyOpen {
                state.hasTrackedMyOpen = true
                RodiAnalytics.track(.myOpened)
            }
            guard !state.isLoadingProfile else { return .none }
            guard state.networkStatus != .disconnected else {
                state.shouldRetryProfileAfterRecovery = state.profile == nil
                return .none
            }
            return loadProfile(state: &state)

        case .retryProfileTapped:
            guard !state.isLoadingProfile else { return .none }
            return loadProfile(state: &state)

        case .networkStatusChanged(let status):
            state.networkStatus = status

            switch status {
            case .checking:
                return .none

            case .disconnected:
                guard state.profile == nil else { return .none }
                state.shouldRetryProfileAfterRecovery = true
                state.hasAutomaticallyRetriedAfterRecovery = false
                return .none

            case .connected:
                return retryProfileAfterRecoveryIfNeeded(state: &state)
            }

        case let .profileLoaded(result, requestID):
            guard requestID == state.profileRequestID else { return .none }
            state.isLoadingProfile = false
            state.hasCompletedInitialLoad = true

            switch result {
            case .success(let profile):
                state.profile = profile
                state.profileErrorMessage = nil
                RodiAnalytics.setUserContext(
                    userMode: "member",
                    loginProvider: nil,
                    memberLevel: profile.level.rawValue,
                    hasDrivingGoal: !(profile.drivingGoal?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                )
                RodiLogger.info("My profile loaded")
            case .failure(let message):
                state.profileErrorMessage = message
                return retryProfileAfterRecoveryIfNeeded(state: &state)
            }

        case .drivingGoalUpdated(let profile):
            state.profile = profile
            state.profileErrorMessage = nil
            return presentSnackbar("운전 목표를 수정했어요.", state: &state)

        case .logoutConfirmed:
            return logout(state: &state)

        case .withdrawalConfirmed:
            return withdraw(state: &state)

        case .sessionEnded(let reason):
            switch reason {
            case .logout:
                RodiAnalytics.track(.logoutCompleted)
                RodiAnalytics.setUserContext(userMode: "guest", loginProvider: nil, memberLevel: nil, hasDrivingGoal: nil)
            case .withdrawal:
                RodiAnalytics.track(.withdrawalRequested)
                RodiAnalytics.setUserContext(userMode: "guest", loginProvider: nil, memberLevel: nil, hasDrivingGoal: nil)
            }
            state.didEndSessionRequestID += 1

        case .snackbarDismissed(let message):
            guard state.snackbarMessage == message else { return .none }
            state.snackbarMessage = nil
        }

        return .none
    }

    func loadProfile(state: inout State) -> Effect<Action> {
        state.isLoadingProfile = true
        state.profileErrorMessage = nil
        state.profileRequestID += 1
        let requestID = state.profileRequestID

        return .run { send in
            do {
                let profile = try await memberRepository.fetchMyProfile()
                await send(.profileLoaded(.success(profile), requestID: requestID))
            } catch {
                #if DEBUG
                RodiLogger.warning("회원 프로필 로드 실패: error=\(error)")
                #else
                RodiLogger.warning("My profile load failed")
                #endif
                await send(.profileLoaded(.failure("내 정보를 불러오지 못했어요."), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.profile)
    }

    func retryProfileAfterRecoveryIfNeeded(state: inout State) -> Effect<Action> {
        guard state.networkStatus == .connected,
              state.shouldRetryProfileAfterRecovery,
              !state.hasAutomaticallyRetriedAfterRecovery,
              !state.isLoadingProfile,
              state.profile == nil
        else {
            return .none
        }

        state.shouldRetryProfileAfterRecovery = false
        state.hasAutomaticallyRetriedAfterRecovery = true
        return loadProfile(state: &state)
    }

    func logout(state: inout State) -> Effect<Action> {
        .run { send in
            do {
                try await authRepository.logout()
                RodiLogger.info("Logout API completed")
            } catch {
                authRepository.clearSession()
                RodiLogger.warning("Logout API failed; local session cleared. error=\(error)")
            }

            await logoutKakaoSDKSessionIfNeeded()
            await send(.sessionEnded(.logout))
        }
        .cancelTask(id: EffectID.session)
    }

    func withdraw(state: inout State) -> Effect<Action> {
        .run { send in
            do {
                try await memberRepository.withdraw()
                RodiLogger.info("Member withdrawal API completed")
            } catch {
                RodiLogger.warning("Member withdrawal API failed. error=\(error)")
                return
            }

            authRepository.clearSession()
            recentLoginProviderStore.clear()
            await logoutKakaoSDKSessionIfNeeded()
            await send(.sessionEnded(.withdrawal))
        }
        .cancelTask(id: EffectID.session)
    }

    func presentSnackbar(_ message: String, state: inout State) -> Effect<Action> {
        state.snackbarMessage = message
        return .run { send in
            try? await Task.sleep(for: .seconds(3))
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }

    func logoutKakaoSDKSessionIfNeeded() async {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            UserApi.shared.logout { error in
                if let error {
                    RodiLogger.warning("Kakao SDK logout failed or no active Kakao session. error=\(error)")
                } else {
                    RodiLogger.info("Kakao SDK logout completed")
                }
                continuation.resume()
            }
        }
        #endif
    }

}
