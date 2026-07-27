//
//  OnboardingEntryReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct OnboardingEntryReducer: Reducer {
    struct State {
        var isAuthenticating = false
        var recentLoginProvider: SocialLoginProvider?

        init(recentLoginProvider: SocialLoginProvider? = nil) {
            self.recentLoginProvider = recentLoginProvider
        }

        var firstSocialProvider: SocialLoginProvider {
            recentLoginProvider ?? .kakao
        }

        var secondSocialProvider: SocialLoginProvider {
            firstSocialProvider == .kakao ? .apple : .kakao
        }

        var socialProviders: [SocialLoginProvider] {
            [firstSocialProvider, secondSocialProvider]
        }
    }

    enum Action {
        case debugOnboardingTapped
        case browseTapped
        case onKakaoLoginTapped
        case onAppleLoginTapped
        case restoreTapped(AuthWithdrawalRecovery)
        case openedURL(URL)
        case authenticationSucceeded(SocialLoginProvider, isNewMember: Bool, nickname: String?)
        case authenticationCancelled
        case authenticationFailed(String)
        case withdrawalRecoveryRequired(AuthWithdrawalRecovery)
        case withdrawalRestoreLocked(rejoinAvailableAt: Date?)
    }

    private let authRepository: AuthRepository
    private let socialLoginService: SocialLoginService

    init(
        authRepository: AuthRepository? = nil,
        socialLoginService: SocialLoginService? = nil
    ) {
        self.authRepository = authRepository ?? AuthDependencyContainer.shared.authRepository
        self.socialLoginService = socialLoginService ?? SocialLoginService()
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .debugOnboardingTapped:
            break

        case .browseTapped:
            authRepository.clearSession()
            RodiLogger.info("Browse mode started; local auth session cleared")
            state.isAuthenticating = false
            break

        case .onKakaoLoginTapped:
            return authenticate(provider: .kakao, state: &state)

        case .onAppleLoginTapped:
            return authenticate(provider: .apple, state: &state)

        case .restoreTapped(let recovery):
            return restore(recovery, state: &state)

        case .openedURL(let url):
            _ = socialLoginService.handleOpenURL(url)

        case .authenticationSucceeded:
            state.isAuthenticating = false

        case .authenticationCancelled:
            state.isAuthenticating = false

        case .authenticationFailed:
            state.isAuthenticating = false

        case .withdrawalRecoveryRequired:
            state.isAuthenticating = false

        case .withdrawalRestoreLocked:
            state.isAuthenticating = false
        }

        return .none
    }

    private func authenticate(provider: SocialLoginProvider, state: inout State) -> Effect<Action> {
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
                    await send(.authenticationFailed(error.localizedDescription))
                }
            case .failure(let error):
                if error.isAppleAuthorizationCancelled {
                    await send(.authenticationCancelled)
                } else {
                    await send(.authenticationFailed(error.localizedDescription))
                }
            }
        }
    }

    private func restore(_ recovery: AuthWithdrawalRecovery, state: inout State) -> Effect<Action> {
        state.isAuthenticating = true

        return .run { send in
            let credentialResult = await credentialResult(for: recovery.provider)
            switch credentialResult {
            case .success(let credential):
                do {
                    let token = try await authRepository.restore(provider: recovery.provider, credential: credential)
                    await send(
                        .authenticationSucceeded(
                            recovery.provider,
                            isNewMember: token.isNewMember,
                            nickname: token.nickname
                        )
                    )
                } catch let error as NetworkError {
                    if case let .apiError(code, _, _) = error, code == "MEMBER_409_1" {
                        await send(.withdrawalRestoreLocked(rejoinAvailableAt: recovery.rejoinAvailableAt))
                    } else {
                        await send(.authenticationFailed(error.localizedDescription))
                    }
                } catch {
                    await send(.authenticationFailed(error.localizedDescription))
                }
            case .failure(let error):
                if error.isAppleAuthorizationCancelled {
                    await send(.withdrawalRecoveryRequired(recovery))
                } else {
                    await send(.authenticationFailed(error.localizedDescription))
                }
            }
        }
    }

    private func credentialResult(for provider: SocialLoginProvider) async -> Result<String, Error> {
        switch provider {
        case .apple:
            await socialLoginService.loginWithApple()
        case .kakao:
            if socialLoginService.isKakaoTalkLoginAvailable {
                await socialLoginService.loginWithKakaoTalk()
            } else {
                await socialLoginService.loginWithKakaoAccount()
            }
        }
    }
}
