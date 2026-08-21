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
    @StateObject private var networkConnectionMonitor: NetworkConnectionMonitor
    private let dependencies: AppDependencies

    init() {
        let onboardingProgressStore = OnboardingProgressStore()
        let dependencies = AppDependencies()
        self.dependencies = dependencies
        let reviewFlowReducer = ReviewFlowFactory.make(
            placeRepository: dependencies.placeRepository,
            practiceRepository: dependencies.practiceRepository,
            reviewRepository: dependencies.reviewRepository
        )
        let practiceTrackingReducer = PracticeTrackingReducer(
            practiceRepository: dependencies.practiceRepository,
            measurementStore: dependencies.practiceMeasurementStore,
            trackingService: dependencies.practiceTrackingService
        )

        _store = StateObject(
            wrappedValue: Store(
                state: RootReducer.State(),
                reducer: RootReducer(
                    tokenStore: dependencies.tokenStore,
                    authRepository: dependencies.authRepository,
                    onboardingProgressStore: onboardingProgressStore,
                    reviewFlowReducer: reviewFlowReducer,
                    practiceTrackingReducer: practiceTrackingReducer
                )
            )
        )
        let networkConnectionMonitor = NetworkConnectionMonitor()
        _networkConnectionMonitor = StateObject(wrappedValue: networkConnectionMonitor)
    }

    var body: some View {
        ZStack {
            rootContent

            if store.state.isLoginRequiredPresented {
                LoginRequiredDialog(
                    dismissAction: { store.send(.loginRequiredDismissed) },
                    kakaoLoginAction: { store.send(.socialLoginRequested(.kakao)) },
                    appleLoginAction: { store.send(.socialLoginRequested(.apple)) }
                )
                .transition(.opacity)
            }

            ReviewFlowHostView(
                state: store.state.reviewFlow,
                send: { store.send(.reviewFlow($0)) }
            )
                .zIndex(2)

            PracticeTrackingView(
                state: store.state.practiceTracking,
                canPresentReviewPrompt: store.state.reviewFlow.review.route == .hidden,
                service: dependencies.practiceTrackingService,
                send: { store.send(.practiceTracking($0)) }
            )
                .zIndex(3)

            if let update = store.state.pendingUpdate {
                RodiMandatoryUpdateDialog {
                    openURL(update.appStoreURL)
                }
                .zIndex(4)
            }

        }
        .rodiSnackbar(message: store.state.reviewFlow.snackbarMessage)
        .overlay(alignment: .bottom) {
            if networkConnectionMonitor.status == .disconnected {
                NetworkConnectionSnackbar(refreshAction: networkConnectionMonitor.refresh)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 96)
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
        .environmentObject(networkConnectionMonitor)
        .onAppear {
            store.send(.launched)
            store.send(.sceneBecameActive)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                store.send(.sceneBecameActive)
            case .inactive, .background:
                store.send(.sceneBecameInactive)
            @unknown default:
                break
            }
        }
        .onOpenURL { url in
            if let sessionID = PracticeLiveActivityDeepLink.sessionID(from: url) {
                if #available(iOS 16.1, *) {
                    PracticeLiveActivityService.shared.cancel(sessionID: sessionID)
                }
                return
            }
            _ = SocialLoginService.handleOpenURL(url)
        }
    }

}


// MARK: - Layout
extension RootView {

    @ViewBuilder
    private var rootContent: some View {
        switch store.state.rootRoute {
        case .launching:
            ZStack {
                RodiColor.white
                    .ignoresSafeArea()
                ProgressView()
                    .tint(RodiColor.primary)
                    .accessibilityLabel("세션 확인 중")
            }

        case .onboarding(let context):
            OnboardingRouterView(
                onComplete: { store.send(.onboardingCompleted(isCourseTutorialCompleted: $0)) },
                automaticLoginProvider: automaticLoginProvider(for: context),
                automaticLoginRequestConsumed: { store.send(.automaticLoginRequestConsumed) },
                dependencies: OnboardingFeatureDependencies(appDependencies: dependencies)
            )

        case .mainTabs:
            MainTabView(
                presentation: MainTabPresentation(
                    consumePendingAuthenticationIntent: {
                        let intent = store.state.pendingAuthenticationIntent
                        store.send(.pendingAuthenticationIntentConsumed)
                        return intent
                    },
                    requestLogin: { store.send(.loginRequired($0)) },
                    onLogoutCompleted: { store.send(.logoutCompleted) },
                    navigationRequestID: store.state.navigationRequestID,
                    homeTabSelectionRequestID: store.state.homeTabSelectionRequestID,
                    homeReviewFlowFinishedRequestID: store.state.reviewFlow.homeFinishedRequestID,
                    myPracticeRecordsReviewFlowFinishedRequestID: store.state.reviewFlow.myPracticeRecordsFinishedRequestID,
                    myPostsReviewFlowFinishedRequestID: store.state.reviewFlow.myPostsFinishedRequestID,
                    onReviewTestRequested: { store.send(.reviewFlow(.debugPromptRequested)) },
                    onReviewRequested: { store.send(.reviewFlow(.requested($0))) },
                    courseDetailReviewPresentation: .init(
                        state: store.state.reviewFlow.review,
                        snackbarMessage: store.state.reviewFlow.snackbarMessage,
                        isPresented: store.state.reviewFlow.entrySource == .courseDetail
                            && store.state.reviewFlow.review.route != .hidden,
                        send: { store.send(.reviewFlow(.review($0))) }
                    ),
                    isCourseTutorialCompleted: store.state.isCourseTutorialCompleted,
                    onCourseTutorialCompleted: { store.send(.courseTutorialCompleted) }
                ),
                dependencies: MainTabFeatureDependencies(appDependencies: dependencies)
            )
        }
    }

    private func automaticLoginProvider(for context: OnboardingLaunchContext) -> SocialLoginProvider? {
        guard case .automaticLogin(let provider) = context else { return nil }
        return provider
    }

}
