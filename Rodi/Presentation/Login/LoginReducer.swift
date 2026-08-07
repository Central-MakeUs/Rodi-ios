//
//  LoginReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct LoginReducer: Reducer {
    struct State {
        enum Presentation: Equatable {
            case loginFailure(String)
            case withdrawal(LoginWithdrawalDialogState)
        }

        var session: OnboardingSession
        var isAuthenticating = false
        var recentLoginProvider: SocialLoginProvider?
        var pendingAuthenticationProvider: SocialLoginProvider?
        var isRestoringWithdrawal = false
        var presentation: Presentation?
        var transition: OnboardingTransition?

        init(session: OnboardingSession, recentLoginProvider: SocialLoginProvider? = nil) {
            self.session = session
            self.recentLoginProvider = recentLoginProvider
        }

        var firstSocialProvider: SocialLoginProvider { recentLoginProvider ?? .kakao }
        var secondSocialProvider: SocialLoginProvider { firstSocialProvider == .kakao ? .apple : .kakao }
        var socialProviders: [SocialLoginProvider] { [firstSocialProvider, secondSocialProvider] }
    }

    enum Action {
        case browseTapped
        case kakaoLoginTapped
        case appleLoginTapped
        case restoreTapped(AuthWithdrawalRecovery)
        case authenticationSucceeded(SocialLoginProvider, isNewMember: Bool, nickname: String?)
        case authenticationCancelled
        case authenticationFailed(String)
        case withdrawalRecoveryRequired(AuthWithdrawalRecovery)
        case withdrawalRestoreLocked(rejoinAvailableAt: Date?)
        case dismissPresentation
        case transitionConsumed
    }

    private let authRepository: AuthRepository
    private let socialLoginService: SocialLoginService

    init(
        authRepository: AuthRepository,
        socialLoginService: SocialLoginService
    ) {
        self.authRepository = authRepository
        self.socialLoginService = socialLoginService
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .browseTapped:
            authRepository.clearSession()
            state.session.mode = .guest
            state.session.nickname = nil
            state.presentation = nil
            RodiAnalytics.track(.browseStarted)
            RodiAnalytics.setUserContext(userMode: "guest", loginProvider: nil, memberLevel: nil, hasDrivingGoal: nil)
            state.transition = .init(updatedSession: state.session, navigation: .push(.terms))

        case .kakaoLoginTapped:
            guard !state.isAuthenticating else { return .none }
            state.pendingAuthenticationProvider = .kakao
            RodiAnalytics.track(.loginAttempted(provider: SocialLoginProvider.kakao.rawValue))
            return authenticate(provider: .kakao, state: &state)

        case .appleLoginTapped:
            guard !state.isAuthenticating else { return .none }
            state.pendingAuthenticationProvider = .apple
            RodiAnalytics.track(.loginAttempted(provider: SocialLoginProvider.apple.rawValue))
            return authenticate(provider: .apple, state: &state)

        case .restoreTapped(let recovery):
            guard !state.isAuthenticating else { return .none }
            state.pendingAuthenticationProvider = recovery.provider
            state.presentation = nil
            state.isRestoringWithdrawal = true
            return restore(recovery, state: &state)

        case .authenticationSucceeded(let provider, let isNewMember, let nickname):
            state.isAuthenticating = false
            state.session.mode = .member(provider)
            state.session.nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            state.pendingAuthenticationProvider = nil
            state.presentation = nil
            if state.isRestoringWithdrawal { RodiAnalytics.track(.withdrawalRestored) }
            state.isRestoringWithdrawal = false
            RodiAnalytics.track(.loginSucceeded(provider: provider.rawValue, isNewMember: isNewMember))
            RodiAnalytics.setUserContext(userMode: "member", loginProvider: provider.rawValue, memberLevel: nil, hasDrivingGoal: nil)
            if !isNewMember {
                RodiAnalytics.track(.onboardingCompleted(entryMode: state.session.entryMode, memberLevel: "existing_member"))
            }
            state.transition = .init(updatedSession: state.session, navigation: isNewMember ? .push(.terms) : .complete)

        case .authenticationCancelled:
            state.isAuthenticating = false
            if let provider = state.pendingAuthenticationProvider {
                RodiAnalytics.track(.loginCancelled(provider: provider.rawValue))
            }
            state.pendingAuthenticationProvider = nil
            state.isRestoringWithdrawal = false

        case .authenticationFailed(let message):
            state.isAuthenticating = false
            let provider = state.pendingAuthenticationProvider?.rawValue ?? "unknown"
            RodiAnalytics.track(.loginFailed(provider: provider, failureCategory: "authentication"))
            state.pendingAuthenticationProvider = nil
            state.isRestoringWithdrawal = false
            state.presentation = .loginFailure(message)

        case .withdrawalRecoveryRequired(let recovery):
            state.isAuthenticating = false
            state.presentation = .withdrawal(.restore(recovery))

        case .withdrawalRestoreLocked(let date):
            state.isAuthenticating = false
            state.presentation = .withdrawal(.rejoinLocked(rejoinAvailableAt: date))

        case .dismissPresentation:
            state.presentation = nil

        case .transitionConsumed:
            state.transition = nil
        }

        return .none
    }
}

private extension LoginReducer {

    func authenticate(provider: SocialLoginProvider, state: inout State) -> Effect<Action> {
        state.isAuthenticating = true
        return .run { send in
            let credentialResult = await credentialResult(for: provider)
            switch credentialResult {
            case .success(let credential):
                do {
                    let result = try await authRepository.login(provider: provider, credential: credential)
                    switch result {
                    case .authenticated(let token):
                        await send(.authenticationSucceeded(provider, isNewMember: token.isNewMember, nickname: token.nickname))
                    case .withdrawalPending(let recovery):
                        await send(.withdrawalRecoveryRequired(recovery))
                    }
                } catch {
                    await send(.authenticationFailed(authenticationFailureMessage(for: provider, error: error)))
                }
            case .failure(let error):
                await send(
                    error.isSocialLoginCancelled
                        ? .authenticationCancelled
                        : .authenticationFailed(authenticationFailureMessage(for: provider, error: error))
                )
            }
        }
    }

    func restore(_ recovery: AuthWithdrawalRecovery, state: inout State) -> Effect<Action> {
        state.isAuthenticating = true
        return .run { send in
            let credentialResult = await credentialResult(for: recovery.provider)
            switch credentialResult {
            case .success(let credential):
                do {
                    let token = try await authRepository.restore(provider: recovery.provider, credential: credential)
                    await send(.authenticationSucceeded(recovery.provider, isNewMember: token.isNewMember, nickname: token.nickname))
                } catch let error as NetworkError {
                    if case let .apiError(code, _, _) = error, code == "MEMBER_409_1" {
                        await send(.withdrawalRestoreLocked(rejoinAvailableAt: recovery.rejoinAvailableAt))
                    } else {
                        await send(.authenticationFailed(authenticationFailureMessage(for: recovery.provider, error: error)))
                    }
                } catch {
                    await send(.authenticationFailed(authenticationFailureMessage(for: recovery.provider, error: error)))
                }
            case .failure(let error):
                await send(
                    error.isSocialLoginCancelled
                        ? .withdrawalRecoveryRequired(recovery)
                        : .authenticationFailed(authenticationFailureMessage(for: recovery.provider, error: error))
                )
            }
        }
    }

    func credentialResult(for provider: SocialLoginProvider) async -> Result<String, Error> {
        switch provider {
        case .apple:
            await socialLoginService.loginWithApple()
        case .kakao:
            await socialLoginService.loginWithKakao()
        }
    }

    func authenticationFailureMessage(for provider: SocialLoginProvider, error: Error) -> String {
        switch provider {
        case .apple:
            error.localizedDescription
        case .kakao:
            error.kakaoLoginFailureMessage
        }
    }

}

struct LoginCommand: Equatable {
    enum Kind: Equatable {
        case login(SocialLoginProvider)
        case restore(AuthWithdrawalRecovery)
    }

    let id = UUID()
    let kind: Kind
}
