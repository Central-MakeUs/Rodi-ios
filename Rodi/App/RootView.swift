//
//  RootView.swift
//  Rodi
//

import SwiftUI

struct RootView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var coordinator: StoreOf<AppCoordinatorReducer>
    @State private var pendingUpdate: AppVersionUpdate?
    @State private var hasCheckedAppVersion = false
    @State private var isRestoringSession = false

    private let tokenStore = AuthDependencyContainer.shared.tokenStore
    private let authRepository = AuthDependencyContainer.shared.authRepository

    init() {
        let preferencesStore = AppPreferencesStore()
        _coordinator = StateObject(
            wrappedValue: Store(
                state: AppCoordinatorReducer.State(
                    hasSeenOnboarding: preferencesStore.hasSeenOnboarding()
                ),
                reducer: AppCoordinatorReducer(
                    preferencesStore: preferencesStore,
                    draftStore: OnboardingDraftStore()
                )
            )
        )
    }

    var body: some View {
        ZStack {
            rootContent

            if isLoginRequiredPresented {
                LoginRequiredDialog(
                    dismissAction: { coordinator.send(.loginRequiredDismissed) },
                    kakaoLoginAction: { coordinator.send(.loginRequested(.kakao)) },
                    appleLoginAction: { coordinator.send(.loginRequested(.apple)) }
                )
                .transition(.opacity)
            }
        }
        #if DEBUG
        .fullScreenCover(isPresented: debugOnboardingBinding) {
            OnboardingView(
                onComplete: { coordinator.send(.debugOnboardingDismissed) },
                mode: .debugTesting
            )
        }
        #endif
        .task {
            await restoreSessionIfNeeded()
            await checkAppVersionIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task { await restoreSessionIfNeeded() }
        }
        .alert("새 버전이 있어요", isPresented: updateAlertBinding) {
            Button("나중에", role: .cancel) { pendingUpdate = nil }
            Button("업데이트") {
                guard let appStoreURL = pendingUpdate?.appStoreURL else { return }
                pendingUpdate = nil
                openURL(appStoreURL)
            }
        } message: {
            Text("더 안정적인 사용을 위해 최신 버전으로 업데이트할 수 있어요.")
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch coordinator.state.route {
        case .onboarding(let context):
            OnboardingView(
                onComplete: { coordinator.send(.onboardingCompleted) },
                onDebugOnboarding: {
                    #if DEBUG
                    coordinator.send(.debugOnboardingRequested)
                    #endif
                },
                automaticLoginProvider: automaticLoginProvider(for: context),
                automaticLoginRequestConsumed: { coordinator.send(.automaticLoginConsumed) }
            )
        case .mainTabs:
            mainTabContent
        }
    }

    @ViewBuilder
    private var mainTabContent: some View {
        ZStack(alignment: .bottom) {
            switch coordinator.state.selectedTab {
            case .home:
                HomeView(
                    selectedTab: selectedTabBinding,
                    pendingPlaceSelection: pendingHomePlaceSelectionBinding,
                    bottomSheetState: homeBottomSheetStateBinding,
                    tabTapRequestID: homeTabTapRequestIDBinding,
                    onAuthenticationRequired: { coordinator.send(.loginRequiredRequested) }
                )
            case .my:
                MyView(
                    isDetailPresented: myDetailPresentationBinding,
                    onSavedPlaceSelected: { coordinator.send(.savedPlaceSelected($0)) },
                    onLogout: { coordinator.send(.logoutCompleted) }
                )
            }

            if shouldShowBottomTabBar {
                RodiBottomTabBar(
                    selectedTab: coordinator.state.selectedTab,
                    homeAction: { coordinator.send(.homeTabTapped) },
                    myAction: { coordinator.send(.myTabTapped(isAuthenticated: hasActiveSession)) }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.1), value: shouldShowBottomTabBar)
    }

    private var selectedTabBinding: Binding<RodiTab> {
        Binding(
            get: { coordinator.state.selectedTab },
            set: { coordinator.send(.selectedTabChanged($0)) }
        )
    }

    private var pendingHomePlaceSelectionBinding: Binding<PlaceListItem?> {
        Binding(
            get: { coordinator.state.pendingHomePlaceSelection },
            set: { coordinator.send(.pendingHomePlaceSelectionChanged($0)) }
        )
    }

    private var homeBottomSheetStateBinding: Binding<HomeBottomSheetState> {
        Binding(
            get: { coordinator.state.homeBottomSheetState },
            set: { coordinator.send(.homeBottomSheetStateChanged($0)) }
        )
    }

    private var homeTabTapRequestIDBinding: Binding<Int> {
        Binding(
            get: { coordinator.state.homeTabTapRequestID },
            set: { coordinator.send(.homeTabTapRequestIDChanged($0)) }
        )
    }

    private var myDetailPresentationBinding: Binding<Bool> {
        Binding(
            get: { coordinator.state.isMyDetailPresented },
            set: { coordinator.send(.myDetailPresentationChanged($0)) }
        )
    }

    private var isLoginRequiredPresented: Bool {
        if case .loginRequired = coordinator.state.presentation { return true }
        return false
    }

    #if DEBUG
    private var debugOnboardingBinding: Binding<Bool> {
        Binding(
            get: {
                if case .debugOnboarding = coordinator.state.presentation { return true }
                return false
            },
            set: { isPresented in
                if !isPresented { coordinator.send(.debugOnboardingDismissed) }
            }
        )
    }
    #endif

    private var shouldShowBottomTabBar: Bool {
        switch coordinator.state.selectedTab {
        case .home:
            coordinator.state.homeBottomSheetState == .collapsed
        case .my:
            !coordinator.state.isMyDetailPresented
        }
    }

    private var hasActiveSession: Bool {
        [tokenStore.accessToken, tokenStore.refreshToken].contains { $0?.isEmpty == false }
    }

    private func automaticLoginProvider(
        for context: AppCoordinatorReducer.OnboardingLaunchContext
    ) -> SocialLoginProvider? {
        guard case .automaticLogin(let provider) = context else { return nil }
        return provider
    }

    private var updateAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingUpdate != nil },
            set: { isPresented in
                if !isPresented { pendingUpdate = nil }
            }
        )
    }

    private func checkAppVersionIfNeeded() async {
        guard !hasCheckedAppVersion else { return }
        hasCheckedAppVersion = true
        pendingUpdate = await AppVersionUpdateChecker.checkForOptionalUpdate()
    }

    @MainActor
    private func restoreSessionIfNeeded() async {
        guard !isRestoringSession,
              let refreshToken = tokenStore.refreshToken,
              !refreshToken.isEmpty
        else { return }

        let needsRefresh = tokenStore.accessToken.map { AccessTokenExpiry.needsRefresh($0) } ?? true
        guard needsRefresh else { return }

        isRestoringSession = true
        defer { isRestoringSession = false }

        do {
            _ = try await authRepository.refreshToken()
            RodiLogger.info("Auth session restore succeeded")
        } catch let error {
            if error.invalidatesAuthSession {
                authRepository.clearSession()
                RodiLogger.info("Auth session restore cleared an invalid session")
            } else {
                RodiLogger.warning("Auth session restore deferred: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    RootView()
}
