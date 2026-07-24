//
//  ContentView.swift
//  Rodi
//
//  Created by mac on 6/26/26.
//

import SwiftUI

struct RootView: View {
    @Environment(\.openURL) private var openURL
    private let preferencesStore = AppPreferencesStore()
    @State private var root: RootDestination
    @State private var pendingUpdate: AppVersionUpdate?
    @State private var hasCheckedAppVersion = false
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
            await checkAppVersionIfNeeded()
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
}

private enum RootDestination {
    case onboarding
    case home
}

#Preview {
    RootView()
}
