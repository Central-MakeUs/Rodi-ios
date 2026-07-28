//
//  MainTabContainer.swift
//  Rodi
//
//  Created by mac on 7/28/26.
//

import SwiftUI

struct MainTabContainer: View {
    @StateObject private var router = MainTabRouter()
    @StateObject private var homeRouter = HomeRouter()
    @StateObject private var myRouter = MyRouter()

    let consumePendingAuthenticationIntent: () -> MainTabIntent?
    let requestMemberAccess: (MainTabIntent) -> Bool
    let requestLogin: () -> Void
    let onLogoutCompleted: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            switch router.selectedTab {
            case .home:
                HomeView(
                    router: homeRouter,
                    isHomeTabSelected: { router.selectedTab == .home },
                    onAuthenticationRequired: requestLogin
                )
            case .my:
                MyView(
                    router: myRouter,
                    navigate: router.navigate,
                    onLogoutCompleted: onLogoutCompleted
                )
            }

            if shouldShowBottomTabBar {
                RodiBottomTabBar(
                    selectedTab: router.selectedTab,
                    homeAction: router.selectHomeTab,
                    myAction: selectMyTab
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.1), value: shouldShowBottomTabBar)
        .onAppear(perform: consumePendingAuthenticationIntentIfNeeded)
        .onChange(of: router.navigationIntent) { intent in
            guard let intent else { return }
            handleNavigationIntent(intent)
        }
    }

}

// MARK: Layout
extension MainTabContainer {

    private var shouldShowBottomTabBar: Bool {
        switch router.selectedTab {
        case .home:
            homeRouter.bottomSheetState == .collapsed
        case .my:
            !myRouter.isDetailPresented
        }
    }

    private func selectMyTab() {
        guard requestMemberAccess(.openMyProfile) else { return }
        router.selectMyTab()
    }

    private func consumePendingAuthenticationIntentIfNeeded() {
        guard let intent = consumePendingAuthenticationIntent() else { return }
        router.navigate(to: intent)
    }

    private func handleNavigationIntent(_ intent: MainTabIntent) {
        switch intent {
        case .presentHomeList:
            homeRouter.requestListPresentation()
        case .openHomePlace(let id):
            homeRouter.showPlace(id: id)
        case .openMyProfile:
            myRouter.popToRoot()
        case .openMySavedPlaces:
            myRouter.popToRoot()
            myRouter.push(.savedPlaces)
        }

        router.consumeNavigationIntent()
    }

}
