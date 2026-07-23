//
//  OnboardingView+Actions.swift
//  Rodi
//

import SwiftUI

extension OnboardingView {
    var selectedTermsPageBinding: Binding<TermsAgreement?> {
        Binding(
            get: { onboardingStore.state.selectedTermsPage },
            set: { onboardingStore.send(.presentation(.setTermsSheet(isPresented: $0 != nil))) }
        )
    }

    var loginAlertBinding: Binding<Bool> {
        Binding(
            get: { onboardingStore.state.loginAlertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    onboardingStore.send(.entry(.dismissLoginAlert))
                }
            }
        )
    }

    func requestLocationPermission() {
        locationPermission.requestPermission()
        onboardingStore.send(.navigation(.locationPermissionContinueTapped))
    }

    func startBrowse() {
        // Keychain persists across app deletion, so guest entry must explicitly end any old session.
        authRepository.clearSession()
        RodiLogger.info("Browse mode started; local auth session cleared")
        onboardingStore.send(.entry(.browseTapped))
    }

    func startAppleLogin() {
        onboardingStore.send(.entry(.authStarted(.apple)))

        Task {
            let result = await socialLoginService.loginWithApple()
            switch result {
            case .success(let credential):
                await completeSocialLogin(provider: .apple, credential: credential)
            case .failure(let error):
                await MainActor.run {
                    onboardingStore.send(.entry(.authFailed(.apple, error.localizedDescription)))
                }
            }
        }
    }

    func startKakaoLogin() {
        onboardingStore.send(.entry(.authStarted(.kakao)))

        Task {
            let result = await kakaoCredentialResult()
            switch result {
            case .success(let credential):
                await completeSocialLogin(provider: .kakao, credential: credential)
            case .failure(let error):
                await MainActor.run {
                    onboardingStore.send(.entry(.authFailed(.kakao, error.localizedDescription)))
                }
            }
        }
    }

    func completeSocialLogin(provider: AuthProvider, credential: String) async {
        do {
            let result = try await authRepository.login(provider: provider, credential: credential)
            await MainActor.run {
                switch result {
                case .authenticated(let token):
                    onboardingStore.send(
                        .entry(
                            .authSucceeded(
                                provider,
                                isNewMember: token.isNewMember,
                                nickname: token.nickname
                            )
                        )
                    )
                case .withdrawalPending(let recovery):
                    onboardingStore.send(.entry(.withdrawalRecoveryRequired(recovery)))
                }
            }
        } catch {
            await MainActor.run {
                onboardingStore.send(.entry(.authFailed(provider, error.localizedDescription)))
            }
        }
    }

    func startWithdrawalRestore(_ recovery: AuthWithdrawalRecovery) {
        onboardingStore.send(.entry(.withdrawalRestoreStarted))

        switch recovery.provider {
        case .apple:
            Task {
                let result = await socialLoginService.loginWithApple()
                await handleWithdrawalCredential(result, recovery: recovery)
            }

        case .kakao:
            Task {
                let result = await kakaoCredentialResult()
                await handleWithdrawalCredential(result, recovery: recovery)
            }
        }
    }

    private func kakaoCredentialResult() async -> Result<String, Error> {
        if socialLoginService.isKakaoTalkLoginAvailable {
            await socialLoginService.loginWithKakaoTalk()
        } else {
            await socialLoginService.loginWithKakaoAccount()
        }
    }

    private func handleWithdrawalCredential(
        _ result: Result<String, Error>,
        recovery: AuthWithdrawalRecovery
    ) async {
        switch result {
        case .success(let credential):
            await restoreWithdrawalAccount(recovery: recovery, credential: credential)
        case .failure(let error):
            await MainActor.run {
                onboardingStore.send(.entry(.authFailed(recovery.provider, error.localizedDescription)))
            }
        }
    }

    private func restoreWithdrawalAccount(
        recovery: AuthWithdrawalRecovery,
        credential: String
    ) async {
        do {
            let token = try await authRepository.restore(provider: recovery.provider, credential: credential)
            await MainActor.run {
                onboardingStore.send(
                    .entry(
                        .authSucceeded(
                            recovery.provider,
                            isNewMember: token.isNewMember,
                            nickname: token.nickname
                        )
                    )
                )
            }
        } catch {
            await MainActor.run {
                if case let .apiError(code, _) = error,
                   code == "MEMBER_409_1" {
                    onboardingStore.send(
                        .entry(.withdrawalRestoreLocked(rejoinAvailableAt: recovery.rejoinAvailableAt))
                    )
                } else {
                    onboardingStore.send(.entry(.authFailed(recovery.provider, error.localizedDescription)))
                }
            }
        }
    }

    func submitOnboarding(drivingGoal: String, shouldSkip: Bool) {
        guard !onboardingStore.state.isOnboardingAnalysisPresented else { return }

        if shouldSkip {
            onboardingStore.send(.optionalDrivingPreference(.skipTapped))
        } else {
            onboardingStore.send(.optionalDrivingPreference(.nextTapped(drivingGoal: drivingGoal)))
        }

        guard onboardingStore.state.isOnboardingAnalysisPresented,
              let submission = onboardingStore.state.memberOnboardingSubmission
        else {
            return
        }

        Task {
            let startedAt = Date()

            do {
                try await memberRepository.submitOnboarding(submission)
                RodiLogger.info("Onboarding submission completed level=\(submission.level.rawValue)")
            } catch {
                // 분석 결과 화면의 흐름은 유지하고, 제출 실패는 로그로만 남깁니다.
                RodiLogger.warning("Onboarding submission failed: \(error.localizedDescription)")
            }

            let remainingDuration = max(0, 3 - Date().timeIntervalSince(startedAt))
            if remainingDuration > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingDuration * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }
            onboardingStore.send(.optionalDrivingPreference(.analysisFinished))
        }
    }
}
