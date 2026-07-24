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
                    if error.isAppleAuthorizationCancelled {
                        onboardingStore.send(.entry(.authCancelled(.apple)))
                    } else {
                        onboardingStore.send(.entry(.authFailed(.apple, error.localizedDescription)))
                    }
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
                if error.isAppleAuthorizationCancelled {
                    onboardingStore.send(.entry(.withdrawalRecoveryRequired(recovery)))
                } else {
                    onboardingStore.send(.entry(.authFailed(recovery.provider, error.localizedDescription)))
                }
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
                if case let .apiError(code, _, _) = error,
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

#if DEBUG
        if mode == .debugTesting {
            RodiLogger.debug("Debug onboarding analysis started level=\(submission.level.rawValue)")
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                guard onboardingStore.state.isOnboardingAnalysisPresented else { return }
                onboardingStore.send(.optionalDrivingPreference(.analysisFinished))
            }
            return
        }
#endif

        Task {
            let startedAt = Date()

            let outcome: OnboardingSubmissionOutcome
            do {
                try await memberRepository.submitOnboarding(submission)
                RodiLogger.info("Onboarding submission completed level=\(submission.level.rawValue)")
                outcome = .completed
            } catch let error as NetworkError {
                RodiLogger.warning("Onboarding submission failed: \(error.localizedDescription)")
                outcome = onboardingSubmissionOutcome(for: error)
            } catch {
                RodiLogger.warning("Onboarding submission failed with an unexpected error: \(error.localizedDescription)")
                outcome = .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
            }

            let remainingDuration = max(0, 3 - Date().timeIntervalSince(startedAt))
            if remainingDuration > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingDuration * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }
            switch outcome {
            case .completed:
                onboardingStore.send(.optionalDrivingPreference(.analysisFinished))
            case .failed(let message):
                onboardingStore.send(.optionalDrivingPreference(.analysisFailed(message)))
            }
        }
    }

    private func onboardingSubmissionOutcome(for error: NetworkError) -> OnboardingSubmissionOutcome {
        if error.isAlreadyCompletedOnboardingSubmission {
            // 앱 재설치 또는 로컬 초안 복원으로 이미 제출된 온보딩을 다시 전송한 경우입니다.
            return .completed
        }

        switch error {
        case .networkUnavailable, .timeOut:
            return .failed("네트워크 연결을 확인한 뒤 다시 시도해 주세요.")
        case .httpStatusCode(let statusCode) where statusCode >= 500:
            return .failed("서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
        case .apiError(_, _, let statusCode?) where statusCode >= 500:
            return .failed("서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
        case .refreshFailGoRoot, .httpStatusCode(401):
            return .failed("로그인 상태를 확인하지 못했어요. 다시 로그인해 주세요.")
        case .apiError(_, _, let statusCode?) where statusCode == 401:
            return .failed("로그인 상태를 확인하지 못했어요. 다시 로그인해 주세요.")
        default:
            return .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
        }
    }
}

private enum OnboardingSubmissionOutcome {
    case completed
    case failed(String)
}

private extension NetworkError {
    var isAlreadyCompletedOnboardingSubmission: Bool {
        switch self {
        case .httpStatusCode(409):
            true
        case .apiError(_, _, let statusCode):
            statusCode == 409
        default:
            false
        }
    }
}
