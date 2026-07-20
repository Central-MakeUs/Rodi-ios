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

    var kakaoLoginMethodDialogBinding: Binding<Bool> {
        Binding(
            get: { onboardingStore.state.isKakaoLoginMethodDialogPresented },
            set: { isPresented in
                if !isPresented {
                    onboardingStore.send(.entry(.kakaoMethodDialogDismissed))
                }
            }
        )
    }

    var kakaoTalkFallbackAlertBinding: Binding<Bool> {
        Binding(
            get: { onboardingStore.state.isKakaoTalkFallbackAlertPresented },
            set: { isPresented in
                if !isPresented {
                    onboardingStore.send(.entry(.kakaoTalkFallbackAlertDismissed))
                }
            }
        )
    }

    func requestLocationPermission() {
        locationPermission.requestPermission()
        onboardingStore.send(.navigation(.locationPermissionContinueTapped))
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
        if socialLoginService.isKakaoTalkLoginAvailable {
            onboardingStore.send(.entry(.kakaoLoginTapped))
        } else {
            onboardingStore.send(.entry(.kakaoTalkUnavailable))
        }
    }

    func startKakaoLogin(method: KakaoLoginMethod) {
        onboardingStore.send(.entry(.kakaoLoginMethodSelected(method)))

        Task {
            let result = await socialLoginService.loginWithKakao(method: method)
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
            let token = try await authRepository.login(provider: provider, credential: credential)
            await MainActor.run {
                onboardingStore.send(
                    .entry(
                        .authSucceeded(
                            provider,
                            isNewMember: token.isNewMember,
                            nickname: token.nickname
                        )
                    )
                )
            }
        } catch {
            await MainActor.run {
                onboardingStore.send(.entry(.authFailed(provider, error.localizedDescription)))
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
