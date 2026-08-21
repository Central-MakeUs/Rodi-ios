//
//  MyView.swift
//  Rodi
//

import Clarity
import SwiftUI

struct MyView: View {
    @EnvironmentObject private var networkConnectionMonitor: NetworkConnectionMonitor
    @ObservedObject var coordinator: Coordinator<MyRoute>
    @StateObject private var store: StoreOf<MyReducer>

    let isMyTabSelected: Bool
    let dataRefreshRequestID: Int
    let navigate: (MainTabIntent) -> Void
    let onLogoutCompleted: () -> Void
    let onReviewTestRequested: () -> Void
    let onReviewRequested: (ReviewWriteRequest) -> Void
    let onReviewEditRequested: (Int) -> Void
    let practiceRecordsNavigationRequestID: Int
    let myPracticeRecordsReviewFlowFinishedRequestID: Int
    let myPostsReviewFlowFinishedRequestID: Int
    let isCourseTutorialCompleted: Bool
    let onCourseTutorialCompleted: () -> Void
    private let destinationDependencies: MyDestinationDependencies
    private var router: Router<MyRoute> { coordinator.router }

    init(
        coordinator: Coordinator<MyRoute>,
        isMyTabSelected: Bool,
        dataRefreshRequestID: Int,
        navigate: @escaping (MainTabIntent) -> Void,
        onLogoutCompleted: @escaping () -> Void,
        onReviewTestRequested: @escaping () -> Void,
        onReviewRequested: @escaping (ReviewWriteRequest) -> Void,
        onReviewEditRequested: @escaping (Int) -> Void,
        practiceRecordsNavigationRequestID: Int,
        myPracticeRecordsReviewFlowFinishedRequestID: Int,
        myPostsReviewFlowFinishedRequestID: Int,
        isCourseTutorialCompleted: Bool,
        onCourseTutorialCompleted: @escaping () -> Void,
        dependencies: MyFeatureDependencies
    ) {
        self.coordinator = coordinator
        self.isMyTabSelected = isMyTabSelected
        self.dataRefreshRequestID = dataRefreshRequestID
        self.navigate = navigate
        self.onLogoutCompleted = onLogoutCompleted
        self.onReviewTestRequested = onReviewTestRequested
        self.onReviewRequested = onReviewRequested
        self.onReviewEditRequested = onReviewEditRequested
        self.practiceRecordsNavigationRequestID = practiceRecordsNavigationRequestID
        self.myPracticeRecordsReviewFlowFinishedRequestID = myPracticeRecordsReviewFlowFinishedRequestID
        self.myPostsReviewFlowFinishedRequestID = myPostsReviewFlowFinishedRequestID
        self.isCourseTutorialCompleted = isCourseTutorialCompleted
        self.onCourseTutorialCompleted = onCourseTutorialCompleted
        _store = StateObject(
            wrappedValue: Store(
                state: MyReducer.State(),
                reducer: MyReducer(
                    authRepository: dependencies.authRepository,
                    memberRepository: dependencies.memberRepository,
                    practiceRepository: dependencies.practiceRepository,
                    recentLoginProviderStore: dependencies.recentLoginProviderStore,
                    levelUpPresentationStore: dependencies.levelUpPresentationStore,
                    socialSessionService: dependencies.socialSessionService
                )
            )
        )
        destinationDependencies = dependencies.destinations
    }

    var body: some View {
        NavigationStack(path: coordinator.pathBinding) {
            MyProfileView(
                profile: store.state.profile,
                isLoading: store.state.isLoadingProfile,
                hasCompletedInitialLoad: store.state.hasCompletedInitialLoad,
                errorMessage: store.state.profileErrorMessage,
                openSettings: { router.push(.settings) },
                openDrivingGoal: { router.push(.drivingGoal) },
                openSavedPlaces: { router.push(.savedPlaces) },
                openPracticeRecords: { router.push(.practiceRecords) },
                openMyPosts: { router.push(.myPosts) },
                retry: { store.send(.retryProfileTapped) },
                practiceRecords: store.state.practiceRecordPreview,
                isLoadingPracticeRecords: store.state.isLoadingPracticeRecords,
                hasCompletedPracticeRecordLoad: store.state.hasCompletedPracticeRecordLoad,
                practiceRecordErrorMessage: store.state.practiceRecordErrorMessage,
                retryPracticeRecords: { store.send(.retryPracticeRecordsTapped) },
                reviewRequested: onReviewRequested,
                reviewTestAction: onReviewTestRequested,
                pendingLevelUp: store.state.pendingLevelUp,
                confirmLevelUp: { store.send(.levelUpDialogConfirmed) }
            )
            .navigationDestination(for: MyRoute.self) { route in
                destinationView(for: route)
                    .background(RodiInteractivePopGestureEnabler())
            }
        }
        .rodiSnackbar(message: store.state.snackbarMessage)
        .task(id: dataRefreshRequestID) {
            guard isMyTabSelected, dataRefreshRequestID > 0 else { return }
            store.send(.networkStatusChanged(networkConnectionMonitor.status))
            store.send(.appeared)
            store.send(.practiceRecordsAppeared)
        }
        .onChange(of: networkConnectionMonitor.status) { status in
            guard isMyTabSelected else { return }
            store.send(.networkStatusChanged(status))
        }
        .onChange(of: store.state.didEndSessionRequestID) { requestID in
            guard requestID > 0 else { return }
            router.popToRoot()
            onLogoutCompleted()
        }
        .onChange(of: myPracticeRecordsReviewFlowFinishedRequestID) { requestID in
            guard requestID > 0 else { return }
            store.send(.practiceRecordsAppeared)
        }
        .clarityMask()
    }

}

// MARK: Layout
private extension MyView {

    @ViewBuilder
    private func destinationView(for route: MyRoute) -> some View {
        switch route {
        case .settings:
            MySettingsView(backAction: { router.pop() }, navigate: { router.push($0) })
            
        case .drivingGoal:
            MyDrivingGoalView(
                initialDrivingGoal: store.state.profile?.drivingGoal ?? "",
                memberRepository: destinationDependencies.memberRepository,
                onUpdated: { store.send(.drivingGoalUpdated($0)) },
                backAction: { router.pop() }
            )
            
        case .savedPlaces:
            SavedPlacesView(
                placeRepository: destinationDependencies.placeRepository,
                backAction: { router.pop() },
                selectPlaceAction: { item in
                    RodiAnalytics.track(.savedPlaceSelected)
                    router.popToRoot()
                    navigate(.openHomePlace(item))
                }
            )

        case .practiceRecords:
            MyPracticeRecordsView(
                practiceRepository: destinationDependencies.practiceRepository,
                reviewRequested: onReviewRequested,
                navigationRefreshRequestID: practiceRecordsNavigationRequestID,
                reviewFlowFinishedRequestID: myPracticeRecordsReviewFlowFinishedRequestID,
                backAction: { router.pop() }
            )

        case .myPosts:
            MyPostsView(
                dependencies: .init(
                    reviewRepository: destinationDependencies.reviewRepository,
                    practiceRepository: destinationDependencies.practiceRepository,
                    courseRepository: destinationDependencies.courseRepository
                ),
                backAction: { router.pop() },
                openPracticeRecords: { router.push(.practiceRecords) },
                openCourseRegistration: { router.push(.courseRegistration) },
                practiceRecordsRefreshRequested: { store.send(.practiceRecordsAppeared) },
                reviewFlowFinishedRequestID: myPostsReviewFlowFinishedRequestID,
                editRequested: onReviewEditRequested
            )

        case .courseRegistration:
            CourseRegistrationView(
                presentation: .init(
                    isTutorialCompleted: isCourseTutorialCompleted,
                    close: { router.pop() },
                    tutorialCompleted: onCourseTutorialCompleted,
                    registrationCompleted: { router.pop() }
                ),
                dependencies: .init(
                    memberRepository: destinationDependencies.memberRepository,
                    courseRepository: destinationDependencies.courseRepository
                )
            )
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            
        case .permissions:
            MyPermissionSettingsView(backAction: { router.pop() })
            
        case .terms:
            MyTermsView(backAction: { router.pop() }, navigate: { router.push($0) })

        case .dataSource:
            MyDataSourceView(backAction: { router.pop() })
            
        case .licenses:
            MyOpenSourceLicenseView(backAction: { router.pop() })
            
        case .accountManagement:
            MyAccountManagementView(
                backAction: { router.pop() },
                navigate: { router.push($0) },
                logoutAction: { store.send(.logoutConfirmed) },
                withdrawalAction: { store.send(.withdrawalConfirmed) }
            )

        case .blockedMembers:
            MyBlockedMembersView(
                memberRepository: destinationDependencies.memberRepository,
                backAction: { router.pop() }
            )
            
        case .contact:
            MyContactView(backAction: { router.pop() })
            
        case .legalDocument(let document):
            MyLegalDocumentView(document: document, backAction: { router.pop() })
        }
    }
}
