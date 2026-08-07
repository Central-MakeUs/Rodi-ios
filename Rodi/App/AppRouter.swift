//
//  AppRouter.swift
//  Rodi
//
//  Created by mac on 7/28/26.
//

import Combine

enum RootRoute: Equatable {
    case onboarding(OnboardingLaunchContext)
    case mainTabs
}

enum OnboardingLaunchContext: Equatable {
    case normal
    case automaticLogin(SocialLoginProvider)
}

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var rootRoute: RootRoute
    @Published private(set) var isLoginRequiredPresented = false
    @Published private(set) var homeTabSelectionRequestID = 0

    private let onboardingProgressStore: OnboardingProgressStore
    private var pendingAuthenticationIntent: MainTabIntent?

    init(
        onboardingProgressStore: OnboardingProgressStore? = nil,
        tokenStore: TokenStoring
    ) {
        let resolvedProgressStore = onboardingProgressStore ?? OnboardingProgressStore()
        self.onboardingProgressStore = resolvedProgressStore

        if resolvedProgressStore.hasInProgressDraft {
            if Self.hasLocalAuthenticationSession(tokenStore) {
                rootRoute = .onboarding(.normal)
            } else {
                resolvedProgressStore.clearDraft()
                rootRoute = .onboarding(.normal)
            }
        } else {
            rootRoute = resolvedProgressStore.hasCompleted ? .mainTabs : .onboarding(.normal)
        }
    }

    func completeOnboarding() {
        homeTabSelectionRequestID += 1
        rootRoute = .mainTabs
    }

    func completeLogout() {
        onboardingProgressStore.reset()
        rootRoute = .onboarding(.normal)
        isLoginRequiredPresented = false
        pendingAuthenticationIntent = nil
    }

    func requireLogin(for intent: MainTabIntent? = nil) {
        if let intent {
            pendingAuthenticationIntent = intent
        }
        isLoginRequiredPresented = true
    }

    func dismissLoginRequired() {
        isLoginRequiredPresented = false
        pendingAuthenticationIntent = nil
    }

    func startLogin(provider: SocialLoginProvider) {
        isLoginRequiredPresented = false
        rootRoute = .onboarding(.automaticLogin(provider))
    }

    func consumeAutomaticLogin() {
        guard case .onboarding(.automaticLogin) = rootRoute else { return }
        rootRoute = .onboarding(.normal)
    }

    func consumePendingAuthenticationIntent() -> MainTabIntent? {
        defer { pendingAuthenticationIntent = nil }
        return pendingAuthenticationIntent
    }

    private static func hasLocalAuthenticationSession(_ tokenStore: TokenStoring) -> Bool {
        guard let accessToken = tokenStore.accessToken,
              let refreshToken = tokenStore.refreshToken
        else {
            return false
        }
        return !accessToken.isEmpty && !refreshToken.isEmpty
    }
}
