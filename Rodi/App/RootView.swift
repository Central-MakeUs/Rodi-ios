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
    
    init() {
        let store = AppPreferencesStore()
        _root = State(initialValue:
                        store.hasSeenOnboarding() ?
                        .home : .onboarding)
    }
    
    var body: some View {
        Group {
            switch root {
            case .onboarding:
                OnboardingView(onComplete: completeOnboarding)
            case .home:
                mainTabContent
            }
        }
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
        preferencesStore.resetOnboardingSeen()
        selectedTab = .home
        root = .onboarding
    }

    @ViewBuilder
    private var mainTabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(selectedTab: $selectedTab)
        case .my:
            MyView(tabBar: bottomTabBar, onLogout: completeLogout)
        }
    }

    private var bottomTabBar: RodiBottomTabBar {
        RodiBottomTabBar(
            selectedTab: selectedTab,
            homeAction: { selectedTab = .home },
            myAction: { selectedTab = .my }
        )
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
