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
    @StateObject private var appRouter: AppRouter
    @StateObject private var networkConnectionMonitor: NetworkConnectionMonitor
    @StateObject private var networkUnavailableOverlayPresenter: NetworkUnavailableOverlayPresenter
    private let dependencies: AppDependencies

    init() {
        let onboardingProgressStore = OnboardingProgressStore()
        let dependencies = AppDependencies()
        self.dependencies = dependencies
        PracticeTrackingService.shared.configure(
            practiceRepository: dependencies.practiceRepository,
            measurementStore: dependencies.practiceMeasurementStore
        )

        _store = StateObject(
            wrappedValue: Store(
                state: RootReducer.State(),
                reducer: RootReducer(
                    tokenStore: dependencies.tokenStore,
                    authRepository: dependencies.authRepository,
                    placeRepository: dependencies.placeRepository,
                    practiceRepository: dependencies.practiceRepository,
                    reviewRepository: dependencies.reviewRepository,
                    practiceMeasurementStore: dependencies.practiceMeasurementStore
                )
            )
        )
        _appRouter = StateObject(
            wrappedValue: AppRouter(
                onboardingProgressStore: onboardingProgressStore,
                tokenStore: dependencies.tokenStore
            )
        )
        let networkConnectionMonitor = NetworkConnectionMonitor()
        _networkConnectionMonitor = StateObject(wrappedValue: networkConnectionMonitor)
        _networkUnavailableOverlayPresenter = StateObject(
            wrappedValue: NetworkUnavailableOverlayPresenter(monitor: networkConnectionMonitor)
        )
    }

    var body: some View {
        ZStack {
            rootContent

            if appRouter.isLoginRequiredPresented {
                LoginRequiredDialog(
                    dismissAction: appRouter.dismissLoginRequired,
                    kakaoLoginAction: { appRouter.startLogin(provider: .kakao) },
                    appleLoginAction: { appRouter.startLogin(provider: .apple) }
                )
                .transition(.opacity)
            }

            if store.state.reviewEntrySource != .courseDetail {
                ReviewFlowView(
                    state: store.state.review,
                    send: { store.send(.review($0)) }
                )
                .zIndex(2)
            }

            if let measurement = store.state.activeMeasurementContinuation {
                ActivePracticeMeasurementDialog(
                    courseName: measurement.placeName,
                    continueAction: { store.send(.activeMeasurementContinued) },
                    endAction: { store.send(.activeMeasurementEnded) }
                )
                .zIndex(3)
            }

            if let update = store.state.pendingUpdate {
                RodiMandatoryUpdateDialog {
                    openURL(update.appStoreURL)
                }
                .zIndex(4)
            }

        }
        .rodiSnackbar(message: store.state.reviewSnackbarMessage)
        .background {
            NetworkUnavailableOverlayHost(presenter: networkUnavailableOverlayPresenter)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .environmentObject(networkConnectionMonitor)
        .onReceive(PracticeTrackingService.shared.$certificationRevision) { _ in
            guard scenePhase == .active else { return }
            store.send(.sceneBecameActive)
        }
        .onAppear {
            store.send(.launched)
            PracticeTrackingService.shared.restoreIfNeeded()
            store.send(.sceneBecameActive)
        }
        .onChange(of: store.state.initialSessionVerification) { verification in
            switch verification {
            case .pending:
                break
            case .authenticated(let isOnboarded, let isCourseTutorialCompleted):
                appRouter.resolveInitialSession(
                    isOnboarded: isOnboarded,
                    isCourseTutorialCompleted: isCourseTutorialCompleted
                )
            case .unauthenticated:
                appRouter.resolveInitialUnauthenticatedSession()
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                PracticeTrackingService.shared.restoreIfNeeded()
                store.send(.sceneBecameActive)
            case .inactive, .background:
                store.send(.sceneBecameInactive)
            @unknown default:
                break
            }
        }
        .onOpenURL { url in
            _ = SocialLoginService.handleOpenURL(url)
        }
    }

}

private struct ActivePracticeMeasurementDialog: View {
    let courseName: String
    let continueAction: () -> Void
    let endAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog {
                VStack(spacing: 0) {
                    Text("‘\(courseName)’")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.primary)
                    Text("아직 코스를 연습 중이신가요?")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                        .padding(.top, 4)
                    Text("코스 주행을 이어서 측정할까요?")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    HStack(spacing: 8) {
                        ReviewDialogButton(title: "측정 종료", isPrimary: false, action: endAction)
                        ReviewDialogButton(title: "계속 측정", isPrimary: true, action: continueAction)
                    }
                    .padding(.top, 24)
                }
            } closeAction: {
                continueAction()
            }
        }
    }
}

// MARK: Layout
extension RootView {

    @ViewBuilder
    private var rootContent: some View {
        switch appRouter.rootRoute {
        case .launching:
            RootLaunchLoadingView()
        case .onboarding(let context):
            OnboardingRouterView(
                onComplete: appRouter.completeOnboarding,
                automaticLoginProvider: automaticLoginProvider(for: context),
                automaticLoginRequestConsumed: appRouter.consumeAutomaticLogin,
                dependencies: dependencies
            )
        case .mainTabs:
            MainTabView(
                consumePendingAuthenticationIntent: appRouter.consumePendingAuthenticationIntent,
                requestLogin: appRouter.requireLogin,
                onLogoutCompleted: appRouter.completeLogout,
                homeTabSelectionRequestID: appRouter.homeTabSelectionRequestID,
                homeReviewFlowFinishedRequestID: store.state.homeReviewFlowFinishedRequestID,
                myPracticeRecordsReviewFlowFinishedRequestID: store.state.myPracticeRecordsReviewFlowFinishedRequestID,
                myPostsReviewFlowFinishedRequestID: store.state.myPostsReviewFlowFinishedRequestID,
                onReviewTestRequested: { store.send(.debugReviewTestRequested) },
                onReviewRequested: { store.send(.reviewRequested($0)) },
                reviewState: store.state.review,
                reviewSnackbarMessage: store.state.reviewSnackbarMessage,
                isCourseDetailReviewPresented: store.state.reviewEntrySource == .courseDetail
                    && store.state.review.route != .hidden,
                sendReview: { store.send(.review($0)) },
                isCourseTutorialCompleted: appRouter.isCourseTutorialCompleted,
                onCourseTutorialCompleted: appRouter.markCourseTutorialCompleted,
                dependencies: dependencies
            )
        }
    }

    private func automaticLoginProvider(for context: OnboardingLaunchContext) -> SocialLoginProvider? {
        guard case .automaticLogin(let provider) = context else { return nil }
        return provider
    }

}

private struct RootLaunchLoadingView: View {
    var body: some View {
        ZStack {
            RodiColor.white
                .ignoresSafeArea()
            ProgressView()
                .tint(RodiColor.primary)
                .accessibilityLabel("세션 확인 중")
        }
    }
}
