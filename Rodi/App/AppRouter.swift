//
//  AppRouter.swift
//  Rodi
//
//  Created by mac on 7/28/26.
//

import Combine

enum RootRoute: Equatable {
    case launching
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
    @Published private(set) var isCourseTutorialCompleted = false

    private let onboardingProgressStore: OnboardingProgressStore
    private var pendingAuthenticationIntent: MainTabIntent?

    init(
        onboardingProgressStore: OnboardingProgressStore? = nil,
        tokenStore: TokenStoring
    ) {
        let resolvedProgressStore = onboardingProgressStore ?? OnboardingProgressStore()
        self.onboardingProgressStore = resolvedProgressStore

        // 로컬 완료 플래그는 앱 삭제·재설치 또는 서버 상태와 어긋날 수 있다.
        // 최초 세션 검증 전에는 홈을 열지 않고, RootReducer가 서버 isOnboarded를
        // 확인한 뒤에만 mainTabs로 전환한다.
        rootRoute = .launching
    }

    func completeOnboarding(isCourseTutorialCompleted: Bool = false) {
        self.isCourseTutorialCompleted = isCourseTutorialCompleted
        homeTabSelectionRequestID += 1
        rootRoute = .mainTabs
    }

    func resolveInitialSession(isOnboarded: Bool, isCourseTutorialCompleted: Bool) {
        guard !isLoginRequiredPresented else { return }
        self.isCourseTutorialCompleted = isCourseTutorialCompleted
        rootRoute = isOnboarded ? .mainTabs : .onboarding(.normal)
    }

    func resolveInitialUnauthenticatedSession() {
        guard !isLoginRequiredPresented else { return }
        isCourseTutorialCompleted = false
        rootRoute = .onboarding(.normal)
    }

    func completeLogout() {
        onboardingProgressStore.reset()
        rootRoute = .onboarding(.normal)
        isLoginRequiredPresented = false
        pendingAuthenticationIntent = nil
        isCourseTutorialCompleted = false
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

    func markCourseTutorialCompleted() {
        isCourseTutorialCompleted = true
    }
}
