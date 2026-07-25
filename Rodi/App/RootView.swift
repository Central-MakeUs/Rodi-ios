//
//  ContentView.swift
//  Rodi
//
//  Created by mac on 6/26/26.
//

import SwiftUI

struct RootView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    private let preferencesStore = AppPreferencesStore()
    @State private var root: RootDestination
    @State private var pendingUpdate: AppVersionUpdate?
    @State private var hasCheckedAppVersion = false
    @State private var isRestoringSession = false
    @State private var selectedTab: RodiTab = .home
    @State private var pendingHomePlaceSelection: PlaceListItem?
    @State private var homeBottomSheetState: HomeBottomSheetState = .collapsed
    @State private var homeTabTapRequestID = 0
    @State private var isMyDetailPresented = false
    @State private var isLoginRequiredDialogPresented = false
    @State private var pendingAutomaticLoginProvider: AuthProvider?
#if DEBUG
    @State private var isDebugOnboardingPresented = false
#endif
    private let tokenStore = AuthDependencyContainer.shared.tokenStore
    private let authRepository = AuthDependencyContainer.shared.authRepository
    
    init() {
        let store = AppPreferencesStore()
        _root = State(initialValue:
                        store.hasSeenOnboarding() ?
                        .home : .onboarding)
    }
    
    var body: some View {
        ZStack {
            Group {
                switch root {
                case .onboarding:
                    OnboardingView(
                        onComplete: completeOnboarding,
                        onDebugOnboarding: {
#if DEBUG
                            isDebugOnboardingPresented = true
#endif
                        },
                        automaticLoginProvider: pendingAutomaticLoginProvider,
                        automaticLoginRequestConsumed: { pendingAutomaticLoginProvider = nil }
                    )
                case .home:
                    mainTabContent
                }
            }

            if isLoginRequiredDialogPresented {
                LoginRequiredDialog(
                    dismissAction: { isLoginRequiredDialogPresented = false },
                    kakaoLoginAction: { startLogin(provider: .kakao) },
                    appleLoginAction: { startLogin(provider: .apple) }
                )
                .transition(.opacity)
            }
        }
#if DEBUG
        .fullScreenCover(isPresented: $isDebugOnboardingPresented) {
            OnboardingView(
                onComplete: { isDebugOnboardingPresented = false },
                mode: .debugTesting
            )
        }
#endif
        .task {
            await restoreSessionIfNeeded()
            PracticeTrackingService.shared.restoreIfNeeded()
            await checkAppVersionIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }

            Task {
                await restoreSessionIfNeeded()
                PracticeTrackingService.shared.restoreIfNeeded()
            }
        }
        .alert("새 버전이 있어요", isPresented: updateAlertBinding) {
            Button("나중에", role: .cancel) {
                pendingUpdate = nil
            }
            
            Button("업데이트") {
                guard let appStoreURL = pendingUpdate?.appStoreURL else { return }
                pendingUpdate = nil
                openURL(appStoreURL)
            }
        } message: {
            Text("더 안정적인 사용을 위해 최신 버전으로 업데이트할 수 있어요.")
        }
    }
    
    private var updateAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingUpdate != nil },
            set: { isPresented in
                if !isPresented {
                    pendingUpdate = nil
                }
            }
        )
    }
    
    private func completeOnboarding() {
        preferencesStore.markOnboardingSeen()
        selectedTab = .home
        root = .home
    }
    
    private func completeLogout() {
        OnboardingDraftStore().clear()
        preferencesStore.resetOnboardingSeen()
        selectedTab = .home
        root = .onboarding
    }

    @ViewBuilder
    private var mainTabContent: some View {
        ZStack(alignment: .bottom) {
            switch selectedTab {
            case .home:
                HomeView(
                    selectedTab: $selectedTab,
                    pendingPlaceSelection: $pendingHomePlaceSelection,
                    bottomSheetState: $homeBottomSheetState,
                    tabTapRequestID: $homeTabTapRequestID,
                    onAuthenticationRequired: beginAuthentication
                )
            case .my:
                MyView(
                    isDetailPresented: $isMyDetailPresented,
                    onSavedPlaceSelected: openSavedPlace,
                    onLogout: completeLogout
                )
            }

            if shouldShowBottomTabBar {
                bottomTabBar
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.1), value: shouldShowBottomTabBar)
    }

    private func openSavedPlace(_ item: PlaceListItem) {
        pendingHomePlaceSelection = item
        selectedTab = .home
    }

    private func beginAuthentication() {
        isLoginRequiredDialogPresented = true
    }

    private func startLogin(provider: AuthProvider) {
        isLoginRequiredDialogPresented = false
        pendingAutomaticLoginProvider = provider
        selectedTab = .home
        root = .onboarding
    }

    private var hasActiveSession: Bool {
        [tokenStore.accessToken, tokenStore.refreshToken]
            .contains { $0?.isEmpty == false }
    }

    private var bottomTabBar: RodiBottomTabBar {
        RodiBottomTabBar(
            selectedTab: selectedTab,
            homeAction: {
                if selectedTab == .home {
                    homeTabTapRequestID += 1
                } else {
                    selectedTab = .home
                }
            },
            myAction: {
                guard hasActiveSession else {
                    isLoginRequiredDialogPresented = true
                    return
                }
                selectedTab = .my
            }
        )
    }

    private var shouldShowBottomTabBar: Bool {
        switch selectedTab {
        case .home:
            homeBottomSheetState == .collapsed
        case .my:
            !isMyDetailPresented
        }
    }
    
    private func checkAppVersionIfNeeded() async {
        guard !hasCheckedAppVersion else { return }
        hasCheckedAppVersion = true
        pendingUpdate = await AppVersionUpdateChecker.checkForOptionalUpdate()
    }

    /// 앱 재진입 시 만료된 access token을 먼저 갱신한다.
    /// 네트워크 장애는 세션을 지우지 않으며, 다음 보호 API 요청에서 다시 갱신을 시도한다.
    @MainActor
    private func restoreSessionIfNeeded() async {
        guard !isRestoringSession else { return }
        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            return
        }

        let needsRefresh: Bool
        if let accessToken = tokenStore.accessToken, !accessToken.isEmpty {
            needsRefresh = AccessTokenExpiry.needsRefresh(accessToken)
        } else {
            needsRefresh = true
        }

        guard needsRefresh else {
            RodiLogger.debug("Auth session restore skipped: access token is still valid")
            return
        }

        isRestoringSession = true
        defer { isRestoringSession = false }

        do {
            _ = try await authRepository.refreshToken()
            RodiLogger.info("Auth session restore succeeded")
        } catch let error as NetworkError {
            if error.invalidatesAuthSession {
                authRepository.clearSession()
                RodiLogger.info("Auth session restore cleared an invalid session")
            } else {
                RodiLogger.warning(
                    "Auth session restore deferred: \(error.localizedDescription)"
                )
            }
        } catch {
            RodiLogger.warning("Auth session restore deferred: \(error.localizedDescription)")
        }
    }
}

private enum RootDestination {
    case onboarding
    case home
}

#Preview {
    RootView()
}
