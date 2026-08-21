//
//  MainTabView.swift
//  Rodi
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.screenSafeAreaInsets) private var screenSafeAreaInsets

    @StateObject private var store: StoreOf<MainTabReducer>
    @StateObject private var myCoordinator = Coordinator<MyRoute>()
    @State private var homeListPresentationRequestID = 0
    @State private var consumedHomeTabSelectionRequestID = 0

    let presentation: MainTabPresentation
    private let dependencies: MainTabFeatureDependencies

    init(
        presentation: MainTabPresentation,
        dependencies: MainTabFeatureDependencies
    ) {
        self.presentation = presentation
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
                presentation: .init(
                    isHomeTabSelected: store.state.selectedTab == .home,
                    listPresentationRequestID: homeListPresentationRequestID,
                    placeSelectionRequest: store.state.homePlaceSelectionRequest,
                    reviewFlowFinishedRequestID: presentation.homeReviewFlowFinishedRequestID,
                    courseDetailReviewPresentation: presentation.courseDetailReviewPresentation,
                    bottomTabBarVisibilityChanged: {
                        store.send(.homeBottomTabBarVisibilityChanged($0))
                    },
                    placeSelectionHandled: {
                        store.send(.homePlaceSelectionHandled($0))
                    },
                    handleDelegate: handleHomeDelegate
                ),
                bottomTabBarHeight: RodiBottomTabBar.totalHeight(
                    safeAreaBottom: screenSafeAreaInsets.bottom
                ),
                dependencies: dependencies.home
            )
                .opacity(store.state.selectedTab == .home ? 1 : 0)
                .allowsHitTesting(store.state.selectedTab == .home)
                .accessibilityHidden(store.state.selectedTab != .home)
            MyView(
                coordinator: myCoordinator,
                isMyTabSelected: store.state.selectedTab == .my,
                dataRefreshRequestID: store.state.myDataRefreshRequestID,
                navigate: { store.send(.navigationRequested($0)) },
                onLogoutCompleted: presentation.onLogoutCompleted,
                onReviewTestRequested: presentation.onReviewTestRequested,
                onReviewRequested: {
                    presentation.onReviewRequested(.init(writeRequest: $0, entrySource: .my))
                },
                onReviewEditRequested: {
                    presentation.onReviewRequested(.init(editingReviewID: $0, entrySource: .myPosts))
                },
                practiceRecordsNavigationRequestID: store.state.practiceRecordsNavigationRequestID,
                myPracticeRecordsReviewFlowFinishedRequestID: presentation.myPracticeRecordsReviewFlowFinishedRequestID,
                myPostsReviewFlowFinishedRequestID: presentation.myPostsReviewFlowFinishedRequestID,
                isCourseTutorialCompleted: presentation.isCourseTutorialCompleted,
                onCourseTutorialCompleted: presentation.onCourseTutorialCompleted,
                dependencies: dependencies.my
            )
            .opacity(store.state.selectedTab == .my ? 1 : 0)
            .allowsHitTesting(store.state.selectedTab == .my)
            .accessibilityHidden(store.state.selectedTab != .my)

            if store.state.selectedTab == .register {
                CourseRegistrationView(
                    presentation: .init(
                        isTutorialCompleted: presentation.isCourseTutorialCompleted,
                        close: { store.send(.courseRegistrationExited) },
                        tutorialCompleted: presentation.onCourseTutorialCompleted,
                        registrationCompleted: { store.send(.courseRegistrationExited) }
                    ),
                    dependencies: .init(
                        memberRepository: dependencies.memberRepository,
                        courseRepository: dependencies.courseRepository
                    )
                )
                .transition(.opacity)
                .zIndex(2)
            }

            if shouldShowBottomTabBar {
                RodiBottomTabBar(
                    selectedTab: store.state.selectedTab,
                    homeAction: { store.send(.homeTabTapped) },
                    registerAction: { store.send(.registerTabTapped) },
                    myAction: { store.send(.myTabTapped) }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.1), value: shouldShowBottomTabBar)
        .onAppear {
            consumePendingAuthenticationIntentIfNeeded()
            selectHomeAfterAuthenticationIfNeeded()
        }
        .onChange(of: presentation.navigationRequestID) { _ in
            consumePendingAuthenticationIntentIfNeeded()
        }
        .onChange(of: presentation.homeTabSelectionRequestID) { _ in
            selectHomeAfterAuthenticationIfNeeded()
        }
        .onChange(of: store.state.navigationIntent) { intent in
            guard let intent else { return }
            handleNavigationIntent(intent)
        }
        .onChange(of: store.state.authenticationIntent) { intent in
            guard let intent else { return }
            presentation.requestLogin(intent)
            store.send(.authenticationRequestHandled)
        }
    }
}

// MARK: Core Logics
private extension MainTabView {

    var shouldShowBottomTabBar: Bool {
        switch store.state.selectedTab {
        case .home:
            store.state.isHomeBottomTabBarVisible

        case .my:
            myCoordinator.path.isEmpty

        case .register:
            false
        }
    }

    func consumePendingAuthenticationIntentIfNeeded() {
        guard let intent = presentation.consumePendingAuthenticationIntent() else { return }
        store.send(.navigationRequested(intent))
    }

    func selectHomeAfterAuthenticationIfNeeded() {
        guard presentation.homeTabSelectionRequestID > consumedHomeTabSelectionRequestID else { return }
        consumedHomeTabSelectionRequestID = presentation.homeTabSelectionRequestID
        store.send(.homeTabSelected)
    }

    func handleNavigationIntent(_ intent: MainTabIntent) {
        switch intent {
        case .openHome:
            break

        case .presentHomeList:
            homeListPresentationRequestID += 1

        case .openHomePlace:
            break
            
        case .openMyProfile:
            myCoordinator.router.popToRoot()

        case .openMySavedPlaces:
            myCoordinator.router.replace(with: [.savedPlaces])

        case .openMyPracticeRecords:
            myCoordinator.router.replace(with: [.practiceRecords])

        case .openCourseRegistration:
            break
        }

        store.send(.navigationHandled)
    }

    func handleHomeDelegate(_ delegate: HomeReducer.Delegate) {
        switch delegate {
        case .requestAuthentication:
            presentation.requestLogin(nil)

        case .reviewWritingRequested(let request):
            presentation.onReviewRequested(.init(writeRequest: request, entrySource: .courseDetail))

        case .reviewEditingRequested(let reviewID):
            presentation.onReviewRequested(.init(editingReviewID: reviewID, entrySource: .courseDetail))

        #if DEBUG
        case .reviewTestRequested:
            presentation.onReviewTestRequested()
        #endif
        }
    }
}
