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

    private let onboardingProgressStore: OnboardingProgressStore
    private var pendingAuthenticationIntent: MainTabIntent?

    init(
        onboardingProgressStore: OnboardingProgressStore? = nil
    ) {
        let resolvedProgressStore = onboardingProgressStore ?? OnboardingProgressStore()
        self.onboardingProgressStore = resolvedProgressStore
        rootRoute = resolvedProgressStore.hasCompleted ? .mainTabs : .onboarding(.normal)
    }

    func completeOnboarding() {
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
}
