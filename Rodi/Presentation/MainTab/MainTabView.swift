//
//  MainTabView.swift
//  Rodi
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var store: StoreOf<MainTabReducer>
    @StateObject private var homeRouter = HomeRouter()
    @StateObject private var myRouter = MyRouter()
    @State private var bottomTabBarHeight: CGFloat = 80

    let consumePendingAuthenticationIntent: () -> MainTabIntent?
    let requestLogin: (MainTabIntent?) -> Void
    let onLogoutCompleted: () -> Void
    private let dependencies: AppDependencies

    init(
        consumePendingAuthenticationIntent: @escaping () -> MainTabIntent?,
        requestLogin: @escaping (MainTabIntent?) -> Void,
        onLogoutCompleted: @escaping () -> Void,
        dependencies: AppDependencies
    ) {
        self.consumePendingAuthenticationIntent = consumePendingAuthenticationIntent
        self.requestLogin = requestLogin
        self.onLogoutCompleted = onLogoutCompleted
        self.dependencies = dependencies
        
        _store = StateObject(
            wrappedValue: Store(
                state: MainTabReducer.State(),
                reducer: MainTabReducer(tokenStore: dependencies.tokenStore)
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeView(
                router: homeRouter,
                isHomeTabSelected: { store.state.selectedTab == .home },
                onAuthenticationRequired: { requestLogin(nil) },
                onBottomSheetStateChanged: { store.send(.homeBottomSheetStateChanged($0)) },
                bottomTabBarHeight: bottomTabBarHeight,
                dependencies: dependencies
            )
            .opacity(store.state.selectedTab == .home ? 1 : 0)
            .allowsHitTesting(store.state.selectedTab == .home)
            .accessibilityHidden(store.state.selectedTab != .home)

            MyView(
                router: myRouter,
                isMyTabSelected: { store.state.selectedTab == .my },
                navigate: { store.send(.navigationRequested($0)) },
                onLogoutCompleted: onLogoutCompleted,
                dependencies: dependencies
            )
            .opacity(store.state.selectedTab == .my ? 1 : 0)
            .allowsHitTesting(store.state.selectedTab == .my)
            .accessibilityHidden(store.state.selectedTab != .my)

            if shouldShowBottomTabBar {
                RodiBottomTabBar(
                    selectedTab: store.state.selectedTab,
                    homeAction: { store.send(.homeTabTapped) },
                    myAction: { store.send(.myTabTapped) }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.1), value: shouldShowBottomTabBar)
        .onPreferenceChange(RodiBottomTabBarHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            bottomTabBarHeight = height
        }
        .onAppear(perform: consumePendingAuthenticationIntentIfNeeded)
        .onChange(of: store.state.navigationIntent) { intent in
            guard let intent else { return }
            handleNavigationIntent(intent)
        }
        .onChange(of: store.state.authenticationIntent) { intent in
            guard let intent else { return }
            requestLogin(intent)
            store.send(.authenticationRequestHandled)
        }
    }
}

// MARK: Core Logics
private extension MainTabView {
    
    var shouldShowBottomTabBar: Bool {
        switch store.state.selectedTab {
        case .home:
            store.state.homeBottomSheetState == .collapsed
            
        case .my:
            !myRouter.isDetailPresented
        }
    }

    func consumePendingAuthenticationIntentIfNeeded() {
        guard let intent = consumePendingAuthenticationIntent() else { return }
        store.send(.navigationRequested(intent))
    }

    func handleNavigationIntent(_ intent: MainTabIntent) {
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

        store.send(.navigationHandled)
    }
}
