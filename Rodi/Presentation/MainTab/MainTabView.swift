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

    let consumePendingAuthenticationIntent: () -> MainTabIntent?
    let requestLogin: (MainTabIntent?) -> Void
    let onLogoutCompleted: () -> Void
    let homeTabSelectionRequestID: Int
    let homeReviewFlowFinishedRequestID: Int
    let myPracticeRecordsReviewFlowFinishedRequestID: Int
    let myPostsReviewFlowFinishedRequestID: Int
    let onReviewTestRequested: () -> Void
    let onReviewRequested: (ReviewFlowRequest) -> Void
    let reviewState: ReviewReducer.State
    let reviewSnackbarMessage: String?
    let isCourseDetailReviewPresented: Bool
    let sendReview: (ReviewReducer.Action) -> Void
    let isCourseTutorialCompleted: Bool
    let onCourseTutorialCompleted: () -> Void
    private let dependencies: AppDependencies

    init(
        consumePendingAuthenticationIntent: @escaping () -> MainTabIntent?,
        requestLogin: @escaping (MainTabIntent?) -> Void,
        onLogoutCompleted: @escaping () -> Void,
        homeTabSelectionRequestID: Int,
        homeReviewFlowFinishedRequestID: Int,
        myPracticeRecordsReviewFlowFinishedRequestID: Int,
        myPostsReviewFlowFinishedRequestID: Int,
        onReviewTestRequested: @escaping () -> Void,
        onReviewRequested: @escaping (ReviewFlowRequest) -> Void,
        reviewState: ReviewReducer.State,
        reviewSnackbarMessage: String?,
        isCourseDetailReviewPresented: Bool,
        sendReview: @escaping (ReviewReducer.Action) -> Void,
        isCourseTutorialCompleted: Bool,
        onCourseTutorialCompleted: @escaping () -> Void,
        dependencies: AppDependencies
    ) {
        self.consumePendingAuthenticationIntent = consumePendingAuthenticationIntent
        self.requestLogin = requestLogin
        self.onLogoutCompleted = onLogoutCompleted
        self.homeTabSelectionRequestID = homeTabSelectionRequestID
        self.homeReviewFlowFinishedRequestID = homeReviewFlowFinishedRequestID
        self.myPracticeRecordsReviewFlowFinishedRequestID = myPracticeRecordsReviewFlowFinishedRequestID
        self.myPostsReviewFlowFinishedRequestID = myPostsReviewFlowFinishedRequestID
        self.onReviewTestRequested = onReviewTestRequested
        self.onReviewRequested = onReviewRequested
        self.reviewState = reviewState
        self.reviewSnackbarMessage = reviewSnackbarMessage
        self.isCourseDetailReviewPresented = isCourseDetailReviewPresented
        self.sendReview = sendReview
        self.isCourseTutorialCompleted = isCourseTutorialCompleted
        self.onCourseTutorialCompleted = onCourseTutorialCompleted
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
                isHomeTabSelected: store.state.selectedTab == .home,
                onAuthenticationRequired: { requestLogin(nil) },
                onReviewTestRequested: onReviewTestRequested,
                onBottomTabBarVisibilityChanged: {
                    store.send(.homeBottomTabBarVisibilityChanged($0))
                },
                listPresentationRequestID: homeListPresentationRequestID,
                placeSelectionRequest: store.state.homePlaceSelectionRequest,
                onPlaceSelectionHandled: {
                    store.send(.homePlaceSelectionHandled($0))
                },
                reviewFlowFinishedRequestID: homeReviewFlowFinishedRequestID,
                onReviewRequested: {
                    onReviewRequested(.init(writeRequest: $0, entrySource: .courseDetail))
                },
                onReviewEditRequested: {
                    onReviewRequested(.init(editingReviewID: $0, entrySource: .courseDetail))
                },
                courseDetailReviewState: reviewState,
                courseDetailReviewSnackbarMessage: reviewSnackbarMessage,
                isCourseDetailReviewPresented: isCourseDetailReviewPresented,
                sendCourseDetailReview: sendReview,
                bottomTabBarHeight: RodiBottomTabBar.totalHeight(
                    safeAreaBottom: screenSafeAreaInsets.bottom
                ),
                dependencies: dependencies
            )
                .opacity(store.state.selectedTab == .home ? 1 : 0)
                .allowsHitTesting(store.state.selectedTab == .home)
                .accessibilityHidden(store.state.selectedTab != .home)
            MyView(
                coordinator: myCoordinator,
                isMyTabSelected: store.state.selectedTab == .my,
                dataRefreshRequestID: store.state.myDataRefreshRequestID,
                navigate: { store.send(.navigationRequested($0)) },
                onLogoutCompleted: onLogoutCompleted,
                onReviewTestRequested: onReviewTestRequested,
                onReviewRequested: {
                    onReviewRequested(.init(writeRequest: $0, entrySource: .my))
                },
                onReviewEditRequested: {
                    onReviewRequested(.init(editingReviewID: $0, entrySource: .myPosts))
                },
                myPracticeRecordsReviewFlowFinishedRequestID: myPracticeRecordsReviewFlowFinishedRequestID,
                myPostsReviewFlowFinishedRequestID: myPostsReviewFlowFinishedRequestID,
                isCourseTutorialCompleted: isCourseTutorialCompleted,
                onCourseTutorialCompleted: onCourseTutorialCompleted,
                dependencies: dependencies
            )
            .opacity(store.state.selectedTab == .my ? 1 : 0)
            .allowsHitTesting(store.state.selectedTab == .my)
            .accessibilityHidden(store.state.selectedTab != .my)

            if store.state.selectedTab == .register {
                CourseRegistrationView(
                    isCourseTutorialCompleted: isCourseTutorialCompleted,
                    memberRepository: dependencies.memberRepository,
                    courseRepository: dependencies.courseRepository,
                    closeAction: { store.send(.courseRegistrationExited) },
                    tutorialCompletedAction: onCourseTutorialCompleted,
                    courseRegistrationCompletedAction: {
                        store.send(.courseRegistrationExited)
                    }
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
        .onChange(of: homeTabSelectionRequestID) { _ in
            selectHomeAfterAuthenticationIfNeeded()
        }
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
            store.state.isHomeBottomTabBarVisible
            
        case .my:
            myCoordinator.path.isEmpty

        case .register:
            false
        }
    }

    func consumePendingAuthenticationIntentIfNeeded() {
        guard let intent = consumePendingAuthenticationIntent() else { return }
        store.send(.navigationRequested(intent))
    }

    func selectHomeAfterAuthenticationIfNeeded() {
        guard homeTabSelectionRequestID > consumedHomeTabSelectionRequestID else { return }
        consumedHomeTabSelectionRequestID = homeTabSelectionRequestID
        store.send(.homeTabSelected)
    }

    func handleNavigationIntent(_ intent: MainTabIntent) {
        switch intent {
        case .presentHomeList:
            homeListPresentationRequestID += 1
            
        case .openHomePlace:
            break
            
        case .openMyProfile:
            myCoordinator.router.popToRoot()
            
        case .openMySavedPlaces:
            myCoordinator.router.replace(with: [.savedPlaces])

        case .openCourseRegistration:
            break
        }

        store.send(.navigationHandled)
    }
}
