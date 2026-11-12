//
//  RootReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct RootReducer: Reducer {

    struct State {
        enum InitialSessionVerification: Equatable {
            case pending
            case authenticated(isOnboarded: Bool, isCourseTutorialCompleted: Bool)
            case unauthenticated
        }

        var pendingUpdate: AppVersionUpdate?
        var hasCheckedAppVersion = false
        var hasCompletedAppVersionCheck = false
        var isSceneActive = false
        var isRestoringSession = false
        var initialSessionVerification: InitialSessionVerification = .pending
        var rootRoute: RootRoute = .launching
        var isLoginRequiredPresented = false
        var pendingAuthenticationIntent: MainTabIntent?
        var navigationRequestID = 0
        var homeTabSelectionRequestID = 0
        var isCourseTutorialCompleted = false
        var reviewFlow = ReviewFlowCoordinatorReducer.State()
        var drivePractice = DrivePracticeReducer.State()
    }

    enum Action {
        case launched
        case sceneBecameActive
        case sceneBecameInactive
        case appVersionCheckCompleted(AppVersionUpdate?)
        case sessionRestoreCompleted(SessionRestoreResult)
        case onboardingCompleted(isCourseTutorialCompleted: Bool)
        case loginRequired(MainTabIntent?)
        case loginRequiredDismissed
        case socialLoginRequested(SocialLoginProvider)
        case automaticLoginRequestConsumed
        case pendingAuthenticationIntentConsumed
        case logoutCompleted
        case courseTutorialCompleted
        case reviewFlow(ReviewFlowCoordinatorReducer.Action)
        case drivePractice(DrivePracticeReducer.Action)
    }

    enum SessionRestoreResult {
        case refreshed(AuthToken)
        case invalidated
        case deferred(String)
    }

    private enum EffectID {
        case appVersionCheck
        case sessionRestore
    }

    private let tokenStore: TokenStoring
    private let authRepository: AuthRepository
    private let onboardingProgressStore: OnboardingProgressStore
    private let reviewFlowReducer: ReviewFlowCoordinatorReducer
    private let drivePracticeReducer: DrivePracticeReducer

    init(
        tokenStore: TokenStoring,
        authRepository: AuthRepository,
        onboardingProgressStore: OnboardingProgressStore,
        reviewFlowReducer: ReviewFlowCoordinatorReducer,
        drivePracticeReducer: DrivePracticeReducer
    ) {
        self.tokenStore = tokenStore
        self.authRepository = authRepository
        self.onboardingProgressStore = onboardingProgressStore
        self.reviewFlowReducer = reviewFlowReducer
        self.drivePracticeReducer = drivePracticeReducer
    }
}


// MARK: - Reduce
extension RootReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .launched:
            return checkAppVersionIfNeeded(state: &state)

        case .sceneBecameActive:
            state.isSceneActive = true
            guard state.hasCompletedAppVersionCheck, state.pendingUpdate == nil else { return .none }
            return restoreSessionIfNeeded(
                state: &state,
                after: .drivePractice(
                    .sceneBecameActive(canPresentPrompt: state.reviewFlow.review.route == .hidden)
                )
            )

        case .sceneBecameInactive:
            state.isSceneActive = false
            return drivePracticeReducer
                .reduce(&state.drivePractice, with: .sceneBecameInactive)
                .map(Action.drivePractice)

        case .appVersionCheckCompleted(let update):
            state.hasCompletedAppVersionCheck = true
            state.pendingUpdate = update
            guard update == nil, state.isSceneActive else { return .none }
            return restoreSessionIfNeeded(
                state: &state,
                after: .drivePractice(
                    .sceneBecameActive(canPresentPrompt: state.reviewFlow.review.route == .hidden)
                )
            )

        case .sessionRestoreCompleted(let result):
            state.isRestoringSession = false
            switch result {
            case .refreshed(let token):
                state.initialSessionVerification = .authenticated(
                    isOnboarded: token.isOnboarded,
                    isCourseTutorialCompleted: token.isCourseTutorialCompleted
                )
                resolveInitialSession(
                    isOnboarded: token.isOnboarded,
                    isCourseTutorialCompleted: token.isCourseTutorialCompleted,
                    state: &state
                )
                RodiLogger.info("Auth session restored")
            case .invalidated:
                authRepository.clearSession()
                if state.initialSessionVerification == .pending {
                    state.initialSessionVerification = .unauthenticated
                    resolveInitialUnauthenticatedSession(state: &state)
                }
                RodiLogger.info("Auth session cleared after refresh rejection")
            case .deferred(let message):
                RodiLogger.warning("Auth session restore deferred: \(message)")
            }
            return .none

        case .onboardingCompleted(let isCourseTutorialCompleted):
            state.isCourseTutorialCompleted = isCourseTutorialCompleted
            state.homeTabSelectionRequestID += 1
            state.rootRoute = .mainTabs
            return .none

        case .loginRequired(let intent):
            if let intent {
                state.pendingAuthenticationIntent = intent
            }
            state.isLoginRequiredPresented = true
            return .none

        case .loginRequiredDismissed:
            state.isLoginRequiredPresented = false
            state.pendingAuthenticationIntent = nil
            return .none

        case .socialLoginRequested(let provider):
            state.isLoginRequiredPresented = false
            state.rootRoute = .onboarding(.automaticLogin(provider))
            return .none

        case .automaticLoginRequestConsumed:
            guard case .onboarding(.automaticLogin) = state.rootRoute else { return .none }
            state.rootRoute = .onboarding(.normal)
            return .none

        case .pendingAuthenticationIntentConsumed:
            state.pendingAuthenticationIntent = nil
            return .none

        case .logoutCompleted:
            onboardingProgressStore.reset()
            state.rootRoute = .onboarding(.normal)
            state.isLoginRequiredPresented = false
            state.pendingAuthenticationIntent = nil
            state.isCourseTutorialCompleted = false
            return drivePracticeReducer
                .reduce(&state.drivePractice, with: .sessionEnded)
                .map(Action.drivePractice)

        case .courseTutorialCompleted:
            state.isCourseTutorialCompleted = true
            return .none

        case .reviewFlow(let action):
            if case .delegate(let delegate) = action {
                return reduceReviewFlowDelegate(delegate)
            }
            return reviewFlowReducer.reduce(&state.reviewFlow, with: action).map(Action.reviewFlow)

        case .drivePractice(let action):
            if case .delegate(let delegate) = action {
                return reduceDrivePracticeDelegate(delegate)
            }
            return drivePracticeReducer
                .reduce(&state.drivePractice, with: action)
                .map(Action.drivePractice)
        }
    }
}

// MARK: - Feature Delegate
private extension RootReducer {

    func reduceReviewFlowDelegate(
        _ delegate: ReviewFlowCoordinatorReducer.Delegate
    ) -> Effect<Action> {
        switch delegate {
        case .practiceReturnPromptInteractionRequested(let interaction):
            return .send(.drivePractice(.promptInteractionRequested(interaction)))
        }
    }

    func reduceDrivePracticeDelegate(
        _ delegate: DrivePracticeReducer.Delegate
    ) -> Effect<Action> {
        switch delegate {
        case .reviewPromptRequested(let prompt):
            return .send(.reviewFlow(.practiceReturnPromptRequested(prompt)))

        case .reviewPromptInteractionReady(let interaction):
            return .send(.reviewFlow(.practiceReturnPromptInteractionResolved(interaction)))

        case .reviewFlowFinishedWithoutReview(let message):
            return .send(.reviewFlow(.practiceReturnFinishedWithoutReview(message)))

        case .showSnackbar(let message):
            return .send(.reviewFlow(.externalSnackbarRequested(message)))
        }
    }
}


// MARK: - Session
private extension RootReducer {

    func checkAppVersionIfNeeded(state: inout State) -> Effect<Action> {
        guard !state.hasCheckedAppVersion else { return .none }
        state.hasCheckedAppVersion = true

        guard AppEnvironment.current.isProduction || AppVersionUpdateChecker.isRequiredUpdateExperimentEnabled else {
            state.hasCompletedAppVersionCheck = true
            return .none
        }

        return .run { send in
            await send(.appVersionCheckCompleted(await AppVersionUpdateChecker.checkForRequiredUpdate()))
        }
        .cancelTask(id: EffectID.appVersionCheck)
    }

    func restoreSessionIfNeeded(
        state: inout State,
        after action: Action?
    ) -> Effect<Action> {
        guard !state.isRestoringSession else { return action.map(Effect.send) ?? .none }
        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            if state.initialSessionVerification == .pending {
                state.initialSessionVerification = .unauthenticated
                resolveInitialUnauthenticatedSession(state: &state)
            }
            return action.map(Effect.send) ?? .none
        }

        let needsRefresh = tokenStore.accessToken.map { AccessTokenExpiry.needsRefresh($0) } ?? true
        let needsInitialVerification = state.initialSessionVerification == .pending
        guard needsInitialVerification || needsRefresh else { return action.map(Effect.send) ?? .none }

        state.isRestoringSession = true
        let authRepository = authRepository
        return .run { send in
            do {
                await send(.sessionRestoreCompleted(.refreshed(try await authRepository.refreshToken())))
            } catch let error as NetworkError {
                await send(.sessionRestoreCompleted(
                    error.invalidatesAuthSession ? .invalidated : .deferred(error.localizedDescription)
                ))
            } catch {
                await send(.sessionRestoreCompleted(.deferred(error.localizedDescription)))
            }
            if let action {
                await send(action)
            }
        }
        .cancelTask(id: EffectID.sessionRestore)
    }

    func resolveInitialSession(
        isOnboarded: Bool,
        isCourseTutorialCompleted: Bool,
        state: inout State
    ) {
        guard !state.isLoginRequiredPresented else { return }
        state.isCourseTutorialCompleted = isCourseTutorialCompleted
        state.rootRoute = isOnboarded ? .mainTabs : .onboarding(.normal)
    }

    func resolveInitialUnauthenticatedSession(state: inout State) {
        guard !state.isLoginRequiredPresented else { return }
        state.isCourseTutorialCompleted = false
        state.rootRoute = .onboarding(.normal)
    }
}
