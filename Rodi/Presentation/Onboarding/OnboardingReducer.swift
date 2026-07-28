//
//  OnboardingReducer.swift
//  Rodi
//

import Foundation

/// 온보딩 입력, 인증, 제출, 초안 보존과 presentation을 관리한다.
/// 실제 화면 전환은 OnboardingRouter가 수행하며, Reducer는 이동 요청만 발행한다.
@MainActor
struct OnboardingReducer: Reducer {
    struct State {
        enum Screen {
            case entry(OnboardingEntryReducer.State)
            case terms(OnboardingTermsReducer.State)
            case nickname(OnboardingNicknameReducer.State)
            case drivingExperience(OnboardingDrivingExperienceReducer.State)
            case optionalDrivingPreference(OnboardingOptionalDrivingPreferenceReducer.State)
            case safety(OnboardingSafetyReducer.State)
            case locationPermission(OnboardingLocationPermissionReducer.State)

            static func make(
                for route: OnboardingRoute,
                draft: OnboardingFlowDraft,
                recentLoginProvider: SocialLoginProvider? = nil
            ) -> Self {
                switch route {
                case .entry: .entry(.init(recentLoginProvider: recentLoginProvider))
                case .terms: .terms(.init(agreedTerms: draft.agreedTerms))
                case .nickname: .nickname(.init(nickname: draft.nickname))
                case .drivingExperience: .drivingExperience(.init(answers: draft.drivingExperience))
                case .optionalDrivingPreference: .optionalDrivingPreference(.init(preferences: draft.preferences))
                case .safety: .safety(.init(agreedSafetyItems: draft.agreedSafetyItems))
                case .locationPermission: .locationPermission(.init())
                }
            }
        }

        var draft: OnboardingFlowDraft
        var screen: Screen
        var presentation: OnboardingPresentation?
        var requestedRoute: OnboardingRoute?
        var didComplete = false

        init(
            payload: OnboardingDraftPayload?,
            initialRoute: OnboardingRoute,
            recentLoginProvider: SocialLoginProvider?
        ) {
            let draft = OnboardingFlowDraft(payload: payload)

            self.draft = draft
            screen = Screen.make(
                for: initialRoute,
                draft: draft,
                recentLoginProvider: recentLoginProvider
            )
        }
    }

    enum Action {
        enum Screen {
            case entry(OnboardingEntryReducer.Action)
            case terms(OnboardingTermsReducer.Action)
            case nickname(OnboardingNicknameReducer.Action)
            case drivingExperience(OnboardingDrivingExperienceReducer.Action)
            case optionalDrivingPreference(OnboardingOptionalDrivingPreferenceReducer.Action)
            case safety(OnboardingSafetyReducer.Action)
            case locationPermission(OnboardingLocationPermissionReducer.Action)
        }

        case screen(route: OnboardingRoute, action: Screen)
        case routeChanged(OnboardingRoute)
        case analysisCompletionConfirmed
        case dismissLoginFailure
        case dismissWithdrawal
        case dismissSnackbar
        case restoreWithdrawal(AuthWithdrawalRecovery)
        case automaticLoginRequested(SocialLoginProvider)
        case submissionCompleted(SubmissionOutcome)
    }

    private enum EffectID {
        case submission
        case snackbar
    }

    private let memberRepository: MemberRepository
    private let draftStore: OnboardingDraftStore
    private let progressStore: OnboardingProgressStore
    private let persistsDraft: Bool

    init(
        memberRepository: MemberRepository? = nil,
        draftStore: OnboardingDraftStore? = nil,
        progressStore: OnboardingProgressStore? = nil,
        persistsDraft: Bool
    ) {
        let resolvedDraftStore = draftStore ?? OnboardingDraftStore()

        self.memberRepository = memberRepository ?? AuthDependencyContainer.shared.memberRepository
        self.draftStore = resolvedDraftStore
        self.progressStore = progressStore ?? OnboardingProgressStore(draftStore: resolvedDraftStore)
        self.persistsDraft = persistsDraft
    }

    static func initialRoute(payload: OnboardingDraftPayload?) -> OnboardingRoute {
        let draft = OnboardingFlowDraft(payload: payload)

        if let payload,
           payload.providerRawValue.isEmpty == false,
           let savedRoute = OnboardingRoute(rawValue: payload.stepRawValue),
           savedRoute != .entry {
            return draft.requiresDrivingExperienceReselection ? .drivingExperience : savedRoute
        }

        return .entry
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .screen(let route, let screenAction):
            return reduceScreenAction(route: route, action: screenAction, state: &state)

        case .routeChanged(let route):
            state.screen = State.Screen.make(
                for: route,
                draft: state.draft
            )
            state.requestedRoute = nil
            persistDraftIfNeeded(state: state, route: route)

        case .analysisCompletionConfirmed:
            state.presentation = nil
            requestRoute(.safety, state: &state)
            persistDraftIfNeeded(state: state, route: .safety)

        case .dismissLoginFailure, .dismissWithdrawal:
            state.presentation = nil

        case .dismissSnackbar:
            if case .snackbar = state.presentation {
                state.presentation = nil
            }

        case .restoreWithdrawal(let recovery):
            state.presentation = nil
            return reduceScreenAction(
                route: .entry,
                action: .entry(.restoreTapped(recovery)),
                state: &state
            )

        case .automaticLoginRequested(let provider):
            guard case .entry = state.screen else { return .none }
            return reduceScreenAction(
                route: .entry,
                action: provider == .kakao ? .entry(.onKakaoLoginTapped) : .entry(.onAppleLoginTapped),
                state: &state
            )

        case .submissionCompleted(let outcome):
            return finishSubmission(outcome, state: &state)
        }

        return .none
    }

    private func reduceScreenAction(
        route: OnboardingRoute,
        action: Action.Screen,
        state: inout State
    ) -> Effect<Action> {
        let effect: Effect<Action.Screen>

        switch (state.screen, action) {
        case (.entry(var childState), .entry(let childAction)):
            effect = OnboardingEntryReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.entry)
            state.screen = .entry(childState)
            handleEntryAction(childAction, state: &state)

        case (.terms(var childState), .terms(let childAction)):
            effect = OnboardingTermsReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.terms)
            state.screen = .terms(childState)
            state.draft.agreedTerms = childState.agreedTerms

            if case .nextTapped = childAction, childState.isAllTermsAgreed {
                requestRoute(state.draft.isBrowseUser ? .safety : .nickname, state: &state)
            }

        case (.nickname(var childState), .nickname(let childAction)):
            effect = OnboardingNicknameReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.nickname)
            state.screen = .nickname(childState)
            state.draft.nickname = childState.nickname

            if case .nextTapped = childAction, childState.canProceed {
                requestRoute(.drivingExperience, state: &state)
            }

        case (.drivingExperience(var childState), .drivingExperience(let childAction)):
            effect = OnboardingDrivingExperienceReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.drivingExperience)
            state.screen = .drivingExperience(childState)
            state.draft.drivingExperience = childState.answers

            if case .nextTapped = childAction, childState.answers.canProceed {
                requestRoute(.optionalDrivingPreference, state: &state)
            }

        case (.optionalDrivingPreference(var childState), .optionalDrivingPreference(let childAction)):
            effect = OnboardingOptionalDrivingPreferenceReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.optionalDrivingPreference)
            state.screen = .optionalDrivingPreference(childState)
            state.draft.preferences = childState.preferences

            switch childAction {
            case .skipTapped:
                return startSubmission(drivingGoal: "", route: route, state: &state)
            case .nextTapped(let goal) where childState.preferences.canProceed:
                return startSubmission(drivingGoal: goal, route: route, state: &state)
            default:
                break
            }

        case (.safety(var childState), .safety(let childAction)):
            effect = OnboardingSafetyReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.safety)
            state.screen = .safety(childState)
            state.draft.agreedSafetyItems = childState.agreedSafetyItems

            if case .nextTapped = childAction, childState.isAllSafetyAgreed {
                requestRoute(.locationPermission, state: &state)
            }

        case (.locationPermission(var childState), .locationPermission(let childAction)):
            effect = OnboardingLocationPermissionReducer()
                .reduce(&childState, with: childAction)
                .map(Action.Screen.locationPermission)
            state.screen = .locationPermission(childState)

            if case .continueTapped = childAction {
                finishOnboarding(state: &state)
            }

        default:
            assertionFailure("Onboarding route and screen action do not match")
            return .none
        }

        let routeForPersistence = state.requestedRoute ?? route
        persistDraftIfNeeded(state: state, route: routeForPersistence)

        return effect.map { .screen(route: route, action: $0) }
    }

    private func handleEntryAction(
        _ action: OnboardingEntryReducer.Action,
        state: inout State
    ) {
        switch action {
        case .browseTapped:
            state.draft.isBrowseUser = true
            state.draft.loginProvider = nil
            state.presentation = nil
            requestRoute(.terms, state: &state)
            RodiLogger.info("Browse mode started; local auth session cleared")

        case .authenticationSucceeded(let provider, let isNewMember, let nickname):
            state.presentation = nil
            state.draft.isBrowseUser = false
            state.draft.loginProvider = provider
            state.draft.nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if isNewMember {
                requestRoute(.terms, state: &state)
            } else {
                finishOnboarding(state: &state)
            }

        case .authenticationCancelled:
            break

        case .authenticationFailed(let message):
            state.presentation = .loginFailure(message)

        case .withdrawalRecoveryRequired(let recovery):
            state.presentation = .withdrawal(.restore(recovery))

        case .withdrawalRestoreLocked(let date):
            state.presentation = .withdrawal(.rejoinLocked(rejoinAvailableAt: date))

        case .onKakaoLoginTapped, .onAppleLoginTapped, .restoreTapped, .openedURL:
            break
        }
    }

    private func requestRoute(_ route: OnboardingRoute, state: inout State) {
        state.requestedRoute = route
    }

    private func startSubmission(
        drivingGoal: String,
        route: OnboardingRoute,
        state: inout State
    ) -> Effect<Action> {
        guard state.presentation == nil,
              let submission = OnboardingSubmissionMapper.make(
                drivingExperience: state.draft.drivingExperience,
                preferences: state.draft.preferences,
                drivingGoal: drivingGoal
              )
        else {
            return .none
        }

        let analysis = MemberOnboardingLevelPolicy.analyze(submission)
        state.presentation = .analyzing(
            .init(
                result: analysis,
                recentFrequency: state.draft.drivingExperience.recentDrivingFrequency
            )
        )
        persistDraftIfNeeded(state: state, route: route)

        let memberRepository = memberRepository

        return .run { send in
            let startedAt = Date()
            let outcome: SubmissionOutcome

            do {
                try await memberRepository.submitOnboarding(submission)
                outcome = .completed
            } catch let error as NetworkError {
                outcome = Self.submissionOutcome(for: error)
            } catch {
                outcome = .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
            }

            let remaining = max(0, 3 - Date().timeIntervalSince(startedAt))
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }
            await send(.submissionCompleted(outcome))
        }
        .cancelTask(id: EffectID.submission)
    }

    private func finishSubmission(
        _ outcome: SubmissionOutcome,
        state: inout State
    ) -> Effect<Action> {
        switch outcome {
        case .completed:
            guard case .analyzing(let analysis) = state.presentation else { return .none }
            state.presentation = .analysisComplete(analysis)
            return .none

        case .failed(let message):
            state.presentation = .snackbar(message)

            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await send(.dismissSnackbar)
            }
            .cancelTask(id: EffectID.snackbar)
        }
    }

    private static func submissionOutcome(for error: NetworkError) -> SubmissionOutcome {
        switch error {
        case .networkUnavailable, .timeOut:
            .failed("네트워크 연결을 확인한 뒤 다시 시도해 주세요.")
        case .httpStatusCode(let code) where code >= 500:
            .failed("서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
        case .apiError(_, _, let code?) where code >= 500:
            .failed("서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
        case .httpStatusCode(let code) where (400..<500).contains(code),
             .apiError(_, _, let code?) where (400..<500).contains(code):
            .completed
        default:
            .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
        }
    }

    private func persistDraftIfNeeded(state: State, route: OnboardingRoute) {
        guard persistsDraft,
              let provider = state.draft.loginProvider,
              !state.draft.isBrowseUser,
              !state.didComplete
        else {
            return
        }

        draftStore.save(state.draft.payload(route: route, provider: provider))
    }

    private func finishOnboarding(state: inout State) {
        state.didComplete = true

        guard persistsDraft else { return }
        progressStore.markCompleted()
    }
}

enum OnboardingPresentation {
    case loginFailure(String)
    case withdrawal(OnboardingWithdrawalDialogState)
    case analyzing(OnboardingAnalysisPresentation)
    case analysisComplete(OnboardingAnalysisPresentation)
    case snackbar(String)
}

struct OnboardingAnalysisPresentation {
    let result: MemberOnboardingAnalysis
    let recentFrequency: RecentDrivingFrequency?
}

enum SubmissionOutcome {
    case completed
    case failed(String)
}

struct OnboardingFlowDraft {
    var loginProvider: SocialLoginProvider?
    var isBrowseUser = false
    var agreedTerms: Set<TermsAgreement>
    var nickname: String
    var drivingExperience: OnboardingDrivingExperienceReducer.Answers
    var preferences: OnboardingOptionalDrivingPreferenceReducer.Preferences
    var agreedSafetyItems: Set<SafetyAgreement>
    let requiresDrivingExperienceReselection: Bool

    init(payload: OnboardingDraftPayload?) {
        let roadExperiences = payload?.roadDrivingExperienceRawValues
            ?? payload?.roadDrivingExperienceRawValue.map { [$0] }
            ?? []
        let savedPeriod = payload?.licenseDrivingPeriodRawValue
        let period = savedPeriod.flatMap(LicenseDrivingPeriod.init(rawValue:))

        loginProvider = payload.flatMap { SocialLoginProvider(rawValue: $0.providerRawValue) }
        agreedTerms = Set(payload?.agreedTermsRawValues.compactMap(TermsAgreement.init(rawValue:)) ?? [])
        nickname = payload?.nickname ?? ""
        drivingExperience = .init(
            licenseDrivingPeriod: period,
            recentDrivingFrequency: payload?.recentDrivingFrequencyRawValue.flatMap(RecentDrivingFrequency.init(rawValue:)),
            selectedRoadDrivingExperiences: roadExperiences.compactMap(RoadDrivingExperience.init(rawValue:)),
            soloDrivingRange: payload?.soloDrivingRangeRawValue.flatMap(SoloDrivingRange.init(rawValue:)),
            soloParkingLevel: payload?.soloParkingLevelRawValue.flatMap(SoloParkingLevel.init(rawValue:))
        )
        preferences = .init(
            selectedPracticeSituations: payload?.practiceSituationRawValues.compactMap(PracticeSituation.init(rawValue:)) ?? [],
            vehicleType: payload?.vehicleTypeRawValue.flatMap(VehicleType.init(rawValue:))
        )
        agreedSafetyItems = Set(payload?.agreedSafetyRawValues.compactMap(SafetyAgreement.init(rawValue:)) ?? [])
        requiresDrivingExperienceReselection = savedPeriod != nil && period == nil
    }

    func payload(route: OnboardingRoute, provider: SocialLoginProvider) -> OnboardingDraftPayload {
        OnboardingDraftPayload(
            stepRawValue: route.rawValue,
            providerRawValue: provider.rawValue,
            nickname: nickname,
            agreedTermsRawValues: agreedTerms.map(\.rawValue).sorted(),
            agreedSafetyRawValues: agreedSafetyItems.map(\.rawValue).sorted(),
            licenseDrivingPeriodRawValue: drivingExperience.licenseDrivingPeriod?.rawValue,
            recentDrivingFrequencyRawValue: drivingExperience.recentDrivingFrequency?.rawValue,
            roadDrivingExperienceRawValue: nil,
            roadDrivingExperienceRawValues: drivingExperience.selectedRoadDrivingExperiences.map(\.rawValue),
            soloDrivingRangeRawValue: drivingExperience.soloDrivingRange?.rawValue,
            soloParkingLevelRawValue: drivingExperience.soloParkingLevel?.rawValue,
            practiceSituationRawValues: preferences.selectedPracticeSituations.map(\.rawValue),
            vehicleTypeRawValue: preferences.vehicleType?.rawValue,
            drivingGoal: ""
        )
    }
}
