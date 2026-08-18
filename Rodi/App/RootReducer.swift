//
//  RootReducer.swift
//  Rodi
//
//  Created by mac on 7/28/26.
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
        var isRestoringSession = false
        var initialSessionVerification: InitialSessionVerification = .pending
        var review = ReviewReducer.State()
        var reviewSnackbarMessage: String?
        var reviewEntrySource: ReviewFlowEntrySource?
        var homeReviewFlowFinishedRequestID = 0
        var myPracticeRecordsReviewFlowFinishedRequestID = 0
        var myPostsReviewFlowFinishedRequestID = 0
        var reviewCompletionRefreshFlowID: UUID?
        var pendingPracticeMeasurement: PracticeMeasurement?
        var activeMeasurementContinuation: PracticeMeasurement?
        var isParkingVisitSubmitting = false
        var isDebugCourseVisitSubmitting = false
    }

    enum Action {
        case launched
        case sceneBecameActive
        case sceneBecameInactive
        case activeMeasurementContinued
        case activeMeasurementEnded
        case appVersionCheckCompleted(AppVersionUpdate?)
        case sessionRestoreCompleted(SessionRestoreResult)
        case debugReviewTestRequested
        case reviewRequested(ReviewFlowRequest)
        case review(ReviewReducer.Action)
        case reviewCompletionRefreshCompleted(flowID: UUID)
        case reviewSnackbarDismissed(String)
        case parkingVisitCompleted(ParkingVisitResult)
        case debugCourseVisitCompleted(DebugCourseVisitResult)
    }

    enum ParkingVisitResult {
        case success
        case failure
    }

    enum DebugCourseVisitResult {
        case success(PracticeMeasurement, DebugCourseVisitIntent)
        case failure
    }

    enum DebugCourseVisitIntent {
        case startWriting
        case deferWriting
    }

    enum SessionRestoreResult {
        case refreshed(AuthToken)
        case invalidated
        case deferred(String)
    }

    private enum EffectID {
        case appVersionCheck
        case sessionRestore
        case reviewSnackbar
        case parkingVisit
        case debugCourseVisit
    }

    private let tokenStore: TokenStoring
    private let authRepository: AuthRepository
    private let reviewReducer: ReviewReducer
    private let practiceMeasurementStore: PracticeMeasurementStoring
    private let practiceRepository: PracticeRepository
    private let reviewRepository: ReviewRepository

    init(
        tokenStore: TokenStoring,
        authRepository: AuthRepository,
        placeRepository: PlaceRepository,
        practiceRepository: PracticeRepository,
        reviewRepository: ReviewRepository,
        practiceMeasurementStore: PracticeMeasurementStoring
    ) {
        self.tokenStore = tokenStore
        self.authRepository = authRepository
        self.practiceMeasurementStore = practiceMeasurementStore
        self.practiceRepository = practiceRepository
        self.reviewRepository = reviewRepository
        reviewReducer = ReviewReducer(
            promptService: ReviewPromptService(
                placeRepository: placeRepository,
                practiceRepository: practiceRepository
            ),
            writingService: ReviewWritingService(
                reviewRepository: reviewRepository
            ),
            skipReasonService: ReviewSkipReasonService(
                practiceRepository: practiceRepository
            )
        )
    }
}

// MARK: Core Logic
extension RootReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .launched:
            return checkAppVersionIfNeeded(state: &state)

        case .sceneBecameActive:
            PracticeTrackingService.shared.retryCertificationIfNeeded()
            let promptAction = preparePracticeReturnPromptIfNeeded(state: &state)
            return restoreSessionIfNeeded(state: &state, after: promptAction)

        case .sceneBecameInactive:
            markRodiInactiveIfNeeded()

        case .activeMeasurementContinued:
            state.activeMeasurementContinuation = nil

        case .activeMeasurementEnded:
            PracticeTrackingService.shared.cancel()
            state.activeMeasurementContinuation = nil
            guard var measurement = practiceMeasurementStore.load() else { return .none }
            guard hasElapsedReviewPromptDelay(since: measurement.externalHandoffAt) else {
                practiceMeasurementStore.clear()
                return .none
            }
            measurement.status = .awaitingReturn
            practiceMeasurementStore.save(measurement)
            return makePracticeReturnPromptAction(
                for: measurement,
                requiresEligibility: false,
                state: &state
            ).map(Effect.send) ?? .none

        case .appVersionCheckCompleted(let update):
            state.pendingUpdate = update

        case .sessionRestoreCompleted(let result):
            state.isRestoringSession = false

            switch result {
            case .refreshed(let token):
                // 토큰 재발급 응답도 서버의 튜토리얼 완료 상태를 세션에 반영한다.
                state.initialSessionVerification = .authenticated(
                    isOnboarded: token.isOnboarded,
                    isCourseTutorialCompleted: token.isCourseTutorialCompleted
                )
                RodiLogger.info("Auth session restored")
            case .invalidated:
                authRepository.clearSession()
                if state.initialSessionVerification == .pending {
                    state.initialSessionVerification = .unauthenticated
                }
                RodiLogger.info("Auth session cleared after refresh rejection")
            case .deferred(let message):
                RodiLogger.warning("Auth session restore deferred: \(message)")
            }

        case .debugReviewTestRequested:
            #if DEBUG
            guard state.review.route == .hidden else { return .none }
            state.reviewEntrySource = .home
            return .send(.review(.debugPromptRequested))
            #else
            return .none
            #endif

        case .reviewRequested(let request):
            guard state.review.route == .hidden else { return .none }
            state.reviewEntrySource = request.entrySource
            switch request.entry {
            case .writing(let writeRequest):
                return .send(.review(.directWritingRequested(writeRequest)))
            case .editing(let reviewID):
                return .send(.review(.editingRequested(reviewID: reviewID)))
            }

        case .review(.prompt(.visitedTapped)):
            guard !state.isParkingVisitSubmitting else { return .none }
            if shouldRegisterParkingVisit(state: state) {
                setPromptVisitSubmitting(true, state: &state)
                return registerParkingVisit(state: &state)
            }
            #if DEBUG
            if shouldRegisterDebugCourseVisit(state: state) {
                return registerDebugCourseVisit(state: &state, intent: .startWriting)
            }
            #endif
            removePracticeReturnPromptIfNeeded(for: .prompt(.visitedTapped), state: &state)
            return reviewReducer
                .reduce(&state.review, with: .prompt(.visitedTapped))
                .map(Action.review)

        case .review(.prompt(.closeTapped)):
            guard !state.isParkingVisitSubmitting else { return .none }
            #if DEBUG
            if shouldRegisterDebugCourseVisit(state: state) {
                return registerDebugCourseVisit(state: &state, intent: .deferWriting)
            }
            #endif
            removePracticeReturnPromptIfNeeded(for: .prompt(.closeTapped), state: &state)
            return reviewReducer
                .reduce(&state.review, with: .prompt(.closeTapped))
                .map(Action.review)

        case .review(.prompt(.notVisitedTapped)):
            guard !state.isParkingVisitSubmitting else { return .none }
            removePracticeReturnPromptIfNeeded(for: .prompt(.notVisitedTapped), state: &state)
            return reviewReducer
                .reduce(&state.review, with: .prompt(.notVisitedTapped))
                .map(Action.review)

        case .review(let action):
            removePracticeReturnPromptIfNeeded(for: action, state: &state)
            if case .delegate(let delegate) = action {
                return reduceReviewDelegate(delegate, state: &state)
            }
            return reviewReducer.reduce(&state.review, with: action).map(Action.review)

        case .reviewCompletionRefreshCompleted(let flowID):
            guard state.reviewCompletionRefreshFlowID == flowID else { return .none }
            state.reviewCompletionRefreshFlowID = nil
            return .send(.review(.writing(.completionRefreshFinished(flowID: flowID))))

        case .reviewSnackbarDismissed(let message):
            guard state.reviewSnackbarMessage == message else { return .none }
            state.reviewSnackbarMessage = nil

        case .parkingVisitCompleted(let result):
            state.isParkingVisitSubmitting = false
            switch result {
            case .success:
                if let measurement = state.pendingPracticeMeasurement {
                    practiceMeasurementStore.remove(measurement)
                }
                state.pendingPracticeMeasurement = nil
                state.review = .init()
                state.reviewEntrySource = nil
                return presentReviewSnackbar("연습 기록에 추가되었습니다.", state: &state)
            case .failure:
                setPromptVisitSubmitting(false, state: &state)
                return presentReviewSnackbar("연습 기록에 추가하지 못했어요. 다시 시도해 주세요.", state: &state)
            }

        case .debugCourseVisitCompleted(let result):
            state.isDebugCourseVisitSubmitting = false
            switch result {
            case .success(let measurement, let intent):
                practiceMeasurementStore.save(measurement)
                state.pendingPracticeMeasurement = measurement
                switch intent {
                case .startWriting:
                    return .send(.review(.prompt(.visitedTapped)))
                case .deferWriting:
                    return .send(.review(.prompt(.closeTapped)))
                }
            case .failure:
                return presentReviewSnackbar("연습 기록에 추가하지 못했어요. 다시 시도해 주세요.", state: &state)
            }
        }

        return .none
    }

    private func checkAppVersionIfNeeded(state: inout State) -> Effect<Action> {
        guard AppEnvironment.current.isProduction else { return .none }
        guard !state.hasCheckedAppVersion else { return .none }

        state.hasCheckedAppVersion = true

        return .run { send in
            let update = await AppVersionUpdateChecker.checkForRequiredUpdate()
            await send(.appVersionCheckCompleted(update))
        }
        .cancelTask(id: EffectID.appVersionCheck)
    }

    private func restoreSessionIfNeeded(
        state: inout State,
        after action: Action?
    ) -> Effect<Action> {
        guard !state.isRestoringSession else {
            return action.map(Effect.send) ?? .none
        }

        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            if state.initialSessionVerification == .pending {
                state.initialSessionVerification = .unauthenticated
            }
            return action.map(Effect.send) ?? .none
        }

        let needsRefresh = tokenStore.accessToken.map { AccessTokenExpiry.needsRefresh($0) } ?? true
        // 앱 프로세스에서 최초 한 번은 access token이 아직 유효해도 재발급한다.
        // refresh 응답의 isOnboarded가 홈 진입의 서버 기준이기 때문이다.
        let needsInitialVerification = state.initialSessionVerification == .pending
        guard needsInitialVerification || needsRefresh else { return action.map(Effect.send) ?? .none }

        state.isRestoringSession = true
        return .run { send in

            do {
                let token = try await authRepository.refreshToken()
                await send(.sessionRestoreCompleted(.refreshed(token)))
            } catch let error as NetworkError {
                if error.invalidatesAuthSession {
                    await send(.sessionRestoreCompleted(.invalidated))
                } else {
                    await send(.sessionRestoreCompleted(.deferred(error.localizedDescription)))
                }
            } catch {
                await send(.sessionRestoreCompleted(.deferred(error.localizedDescription)))
            }
            if let action {
                await send(action)
            }
        }
        .cancelTask(id: EffectID.sessionRestore)
    }

    private var hasActiveSession: Bool {
        [tokenStore.accessToken, tokenStore.refreshToken].contains { $0?.isEmpty == false }
    }

    private func preparePracticeReturnPromptIfNeeded(state: inout State) -> Action? {
        guard state.review.route == .hidden,
              state.pendingPracticeMeasurement == nil,
              let measurement = practiceMeasurementStore.load()
        else {
            return nil
        }

        if measurement.isActiveTracking,
           PracticeTrackingService.shared.hasActiveMeasurement {
            state.activeMeasurementContinuation = measurement
            return nil
        }

        return makePracticeReturnPromptAction(for: measurement, state: &state)
    }

    private func makePracticeReturnPromptAction(
        for measurement: PracticeMeasurement,
        requiresEligibility: Bool = true,
        state: inout State
    ) -> Action? {
        guard !requiresEligibility || isReviewEligible(measurement) else { return nil }
        state.pendingPracticeMeasurement = measurement
        state.reviewEntrySource = .home
        return .review(.promptRequested(
            placeID: measurement.placeID,
            placeName: measurement.placeName,
            allowsSkipReason: true,
            allowsReviewWriting: !measurement.isParking,
            visitedSnackbarMessage: measurement.isParking
                ? "연습 기록에 추가되었습니다."
                : nil
        ))
    }

    private func removePracticeReturnPromptIfNeeded(
        for action: ReviewReducer.Action,
        state: inout State
    ) {
        guard state.review.route == .prompt,
              let prompt = state.pendingPracticeMeasurement
        else {
            return
        }

        switch action {
        case .prompt(.closeTapped), .prompt(.notVisitedTapped), .prompt(.visitedTapped):
            practiceMeasurementStore.remove(prompt)
            state.pendingPracticeMeasurement = nil
        default:
            break
        }
    }

    private func markRodiInactiveIfNeeded() {
        guard var measurement = practiceMeasurementStore.load() else { return }
        measurement.lastRodiInactiveAt = .now
        practiceMeasurementStore.save(measurement)
    }

    private func isReviewEligible(_ measurement: PracticeMeasurement) -> Bool {
        guard measurement.status == .certified || measurement.status == .awaitingReturn
        else {
            return false
        }
        return hasElapsedReviewPromptDelay(since: measurement.externalHandoffAt)
    }

    private func hasElapsedReviewPromptDelay(since inactiveAt: Date?) -> Bool {
        guard let inactiveAt else { return false }
        return Date.now.timeIntervalSince(inactiveAt) >= reviewPromptDelay
    }

    // TODO : 후기 작성 권유 팝업 시간 딜레이 (윤수)
    private var reviewPromptDelay: TimeInterval {
        #if DEBUG
        10
        #else
        10 * 60
        #endif
    }

    private func reduceReviewDelegate(
        _ delegate: ReviewReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .finished:
            let entrySource = state.reviewEntrySource
            state.review = .init()
            state.reviewEntrySource = nil
            if entrySource == .home {
                state.homeReviewFlowFinishedRequestID += 1
            }
            if entrySource == .courseDetail {
                state.homeReviewFlowFinishedRequestID += 1
            }
            if entrySource == .my {
                state.myPracticeRecordsReviewFlowFinishedRequestID += 1
                state.myPostsReviewFlowFinishedRequestID += 1
            }
            if entrySource == .myPosts {
                state.myPostsReviewFlowFinishedRequestID += 1
            }
            return .none

        case .completionRefreshRequested(let target, let flowID):
            guard state.reviewCompletionRefreshFlowID == nil,
                  let entrySource = state.reviewEntrySource
            else {
                return .none
            }
            state.reviewCompletionRefreshFlowID = flowID
            return refreshReviewEntryData(
                for: entrySource,
                placeID: target.placeID,
                flowID: flowID
            )

        case .showSnackbar(let message):
            state.reviewSnackbarMessage = message
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                await send(.reviewSnackbarDismissed(message))
            }
            .cancelTask(id: EffectID.reviewSnackbar)

        case .visitedWithoutReview(let message):
            state.reviewSnackbarMessage = message
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                await send(.reviewSnackbarDismissed(message))
            }
            .cancelTask(id: EffectID.reviewSnackbar)

        case .editingFailed(let message):
            state.review = .init()
            state.reviewEntrySource = nil
            state.reviewSnackbarMessage = message
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                await send(.reviewSnackbarDismissed(message))
            }
            .cancelTask(id: EffectID.reviewSnackbar)
        }
    }

    private func shouldRegisterParkingVisit(state: State) -> Bool {
        guard !state.isParkingVisitSubmitting,
              let measurement = state.pendingPracticeMeasurement
        else {
            return false
        }
        return measurement.isParking && measurement.status != .certified
    }

    private func registerParkingVisit(state: inout State) -> Effect<Action> {
        guard let measurement = state.pendingPracticeMeasurement else { return .none }
        state.isParkingVisitSubmitting = true
        let practiceRepository = practiceRepository

        return .run { send in
            do {
                let registration = try await practiceRepository.register(placeID: measurement.placeID)
                _ = try await practiceRepository.recordVisit(
                    practiceID: registration.practiceID,
                    certifiedDistanceMeters: nil
                )
                await send(.parkingVisitCompleted(.success))
            } catch {
                await send(.parkingVisitCompleted(.failure))
            }
        }
        .cancelTask(id: EffectID.parkingVisit)
    }

    private func setPromptVisitSubmitting(_ isSubmitting: Bool, state: inout State) {
        _ = reviewReducer.reduce(
            &state.review,
            with: .prompt(.visitSubmissionChanged(isSubmitting))
        )
    }

    #if DEBUG
    private func shouldRegisterDebugCourseVisit(state: State) -> Bool {
        guard !state.isDebugCourseVisitSubmitting,
              let measurement = state.pendingPracticeMeasurement
        else {
            return false
        }
        return !measurement.isParking && measurement.status != .certified
    }

    private func registerDebugCourseVisit(
        state: inout State,
        intent: DebugCourseVisitIntent
    ) -> Effect<Action> {
        guard let measurement = state.pendingPracticeMeasurement else { return .none }
        state.isDebugCourseVisitSubmitting = true
        let practiceRepository = practiceRepository

        return .run { send in
            do {
                let registration = try await practiceRepository.register(placeID: measurement.placeID)
                _ = try await practiceRepository.recordVisit(
                    practiceID: registration.practiceID,
                    certifiedDistanceMeters: nil
                )
                var registeredMeasurement = measurement
                registeredMeasurement.practiceID = registration.practiceID
                registeredMeasurement.status = .certified
                await send(.debugCourseVisitCompleted(.success(registeredMeasurement, intent)))
            } catch {
                await send(.debugCourseVisitCompleted(.failure))
            }
        }
        .cancelTask(id: EffectID.debugCourseVisit)
    }
    #endif

    private func presentReviewSnackbar(
        _ message: String,
        state: inout State
    ) -> Effect<Action> {
        state.reviewSnackbarMessage = message
        return .run { send in
            try? await Task.sleep(for: .seconds(3))
            await send(.reviewSnackbarDismissed(message))
        }
        .cancelTask(id: EffectID.reviewSnackbar)
    }

    private func refreshReviewEntryData(
        for entrySource: ReviewFlowEntrySource,
        placeID: Int,
        flowID: UUID
    ) -> Effect<Action> {
        let practiceRepository = practiceRepository
        let reviewRepository = reviewRepository

        return .run { send in
            switch entrySource {
            case .courseDetail:
                _ = try? await reviewRepository.fetchReviews(
                    placeID: placeID,
                    query: .init(level: .current)
                )
            case .home, .my:
                _ = try? await practiceRepository.fetchMyPractices(query: .init(size: 20))
            case .myPosts:
                _ = try? await reviewRepository.fetchMyReviews(query: .init(size: 10))
            }
            await send(.reviewCompletionRefreshCompleted(flowID: flowID))
        }
    }
}
