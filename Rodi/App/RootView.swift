//
//  RootView.swift
//  Rodi
//
//  Created by mac on 7/28/26.
//

import SwiftUI

struct RootView: View {

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var store: StoreOf<RootReducer>
    @StateObject private var appRouter: AppRouter
    @StateObject private var networkConnectionMonitor: NetworkConnectionMonitor
    @StateObject private var networkUnavailableOverlayPresenter: NetworkUnavailableOverlayPresenter
    private let dependencies: AppDependencies

    init() {
        let onboardingProgressStore = OnboardingProgressStore()
        let dependencies = AppDependencies()
        self.dependencies = dependencies

        _store = StateObject(
            wrappedValue: Store(
                state: RootReducer.State(),
                reducer: RootReducer(
                    tokenStore: dependencies.tokenStore,
                    authRepository: dependencies.authRepository
                )
            )
        )
        _appRouter = StateObject(
            wrappedValue: AppRouter(
                onboardingProgressStore: onboardingProgressStore,
                tokenStore: dependencies.tokenStore
            )
        )
        let networkConnectionMonitor = NetworkConnectionMonitor()
        _networkConnectionMonitor = StateObject(wrappedValue: networkConnectionMonitor)
        _networkUnavailableOverlayPresenter = StateObject(
            wrappedValue: NetworkUnavailableOverlayPresenter(monitor: networkConnectionMonitor)
        )
    }

    var body: some View {
        ZStack {
            rootContent

            if appRouter.isLoginRequiredPresented {
                LoginRequiredDialog(
                    dismissAction: appRouter.dismissLoginRequired,
                    kakaoLoginAction: { appRouter.startLogin(provider: .kakao) },
                    appleLoginAction: { appRouter.startLogin(provider: .apple) }
                )
                .transition(.opacity)
            }

        }
        .background {
            NetworkUnavailableOverlayHost(presenter: networkUnavailableOverlayPresenter)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .environmentObject(networkConnectionMonitor)
        .onAppear {
            store.send(.launched)
            store.send(.sceneBecameActive)
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            store.send(.sceneBecameActive)
        }
        .onOpenURL { url in
            _ = SocialLoginService.handleOpenURL(url)
        }
        .alert("새 버전이 있어요", isPresented: updateAlertBinding) {
            Button("나중에", role: .cancel) {
                store.send(.appVersionUpdateDismissed)
            }
            Button("업데이트") {
                guard let appStoreURL = store.state.pendingUpdate?.appStoreURL else { return }
                store.send(.appVersionUpdateDismissed)
                openURL(appStoreURL)
            }
        } message: {
            Text("더 안정적인 사용을 위해 최신 버전으로 업데이트할 수 있어요.")
        }
    }

}

// MARK: Layout
extension RootView {

    @ViewBuilder
    private var rootContent: some View {
        switch appRouter.rootRoute {
        case .onboarding(let context):
            OnboardingRouterView(
                onComplete: appRouter.completeOnboarding,
                automaticLoginProvider: automaticLoginProvider(for: context),
                automaticLoginRequestConsumed: appRouter.consumeAutomaticLogin,
                dependencies: dependencies
            )
        case .mainTabs:
            MainTabView(
                consumePendingAuthenticationIntent: appRouter.consumePendingAuthenticationIntent,
                requestLogin: appRouter.requireLogin,
                onLogoutCompleted: appRouter.completeLogout,
                homeTabSelectionRequestID: appRouter.homeTabSelectionRequestID,
                dependencies: dependencies
            )
        }
    }

    private func automaticLoginProvider(for context: OnboardingLaunchContext) -> SocialLoginProvider? {
        guard case .automaticLogin(let provider) = context else { return nil }
        return provider
    }

    private var updateAlertBinding: Binding<Bool> {
        Binding(
            get: { store.state.pendingUpdate != nil },
            set: { isPresented in
                if !isPresented {
                    store.send(.appVersionUpdateDismissed)
                }
            }
        )
    }

}
