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
                onboardingStore.send(.entry(.authSucceeded(provider, isNewMember: token.isNewMember)))
            }
        } catch {
            await MainActor.run {
                onboardingStore.send(.entry(.authFailed(provider, error.localizedDescription)))
            }
        }
    }
}
