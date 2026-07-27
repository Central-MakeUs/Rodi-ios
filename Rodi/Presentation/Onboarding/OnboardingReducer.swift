//
//  OnboardingReducer.swift
//  Rodi
//

import Foundation

/// 온보딩 화면 전환과 제출처럼 여러 화면의 값을 함께 알아야 하는 일만 맡는다.
@MainActor
struct OnboardingReducer: Reducer {
    struct State {
        var route: OnboardingRoute
        var draft: OnboardingFlowDraft
        var screen: OnboardingScreenState
        var presentation: OnboardingPresentation?
        var didComplete = false
        var debugOnboardingRequestID = 0

        init(
            draft payload: OnboardingDraftPayload? = nil,
            recentLoginProvider: SocialLoginProvider? = nil,
            isDebugTesting: Bool = false
        ) {
            let flowDraft = OnboardingFlowDraft(payload: payload)
            draft = flowDraft
            presentation = nil

            if isDebugTesting {
                draft.loginProvider = .kakao
                route = .terms
            } else if let payload,
                      payload.providerRawValue.isEmpty == false,
                      let savedRoute = OnboardingRoute(rawValue: payload.stepRawValue),
                      savedRoute != .entry {
                route = flowDraft.requiresDrivingExperienceReselection ? .drivingExperience : savedRoute
            } else {
                route = .entry
            }

            screen = OnboardingScreenState.make(
                for: route,
                draft: draft,
                recentLoginProvider: recentLoginProvider
            )
        }

        mutating func move(to route: OnboardingRoute) {
            self.route = route
            screen = OnboardingScreenState.make(for: route, draft: draft)
        }
    }

    enum Action {
        case navigation(NavigationAction)
        case screen(OnboardingScreenAction)
        case presentation(PresentationAction)
        case submissionFinished(SubmissionOutcome)

        enum NavigationAction {
            case backTapped
        }

        enum PresentationAction {
            case dismissLoginFailure
            case dismissWithdrawal
            case restoreWithdrawal(AuthWithdrawalRecovery)
            case analysisCompletionConfirmed
            case dismissSnackbar
        }
    }

    private let entryReducer: OnboardingEntryReducer
    private let termsReducer = OnboardingTermsReducer()
    private let nicknameReducer = OnboardingNicknameReducer()
    private let drivingExperienceReducer = OnboardingDrivingExperienceReducer()
    private let optionalPreferenceReducer = OnboardingOptionalDrivingPreferenceReducer()
    private let safetyReducer = OnboardingSafetyReducer()
    private let locationPermissionReducer = OnboardingLocationPermissionReducer()
    private let memberRepository: MemberRepository
    private let draftStore: OnboardingDraftStore
    private let persistsDraft: Bool
    private let isDebugTesting: Bool

    init(
        isDebugTesting: Bool,
        memberRepository: MemberRepository,
        draftStore: OnboardingDraftStore,
        persistsDraft: Bool
    ) {
        entryReducer = OnboardingEntryReducer()
        self.memberRepository = memberRepository
        self.draftStore = draftStore
        self.persistsDraft = persistsDraft
        self.isDebugTesting = isDebugTesting
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        let effect: Effect<Action>

        switch action {
        case .navigation(.backTapped):
            if let previous = state.route.previous {
                state.move(to: previous)
            }
            effect = .none

        case .screen(let action):
            effect = reduceScreen(action, state: &state)

        case .presentation(let action):
            effect = reducePresentation(action, state: &state)

        case .submissionFinished(let outcome):
            effect = reduceSubmission(outcome, state: &state)
        }

        persistDraftIfNeeded(for: state)
        if state.didComplete, persistsDraft {
            draftStore.clear()
        }
        return effect
    }
}

private extension OnboardingReducer {
    func reduceScreen(
        _ action: OnboardingScreenAction,
        state: inout State
    ) -> Effect<Action> {
        switch (state.screen, action) {
        case (.entry(var childState), .entry(let childAction)):
            let effect = entryReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.entry($0)) }
            state.screen = .entry(childState)
            reduceEntry(childAction, state: &state)
            return effect

        case (.terms(var childState), .terms(let childAction)):
            let effect = termsReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.terms($0)) }
            state.screen = .terms(childState)
            state.draft.agreedTerms = childState.agreedTerms
            if case .nextTapped = childAction, childState.isAllTermsAgreed {
                state.move(to: state.draft.isBrowseUser ? .safety : .nickname)
            }
            return effect

        case (.nickname(var childState), .nickname(let childAction)):
            let effect = nicknameReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.nickname($0)) }
            state.screen = .nickname(childState)
            state.draft.nickname = childState.nickname
            if case .nextTapped = childAction, childState.canProceed {
                state.move(to: .drivingExperience)
            }
            return effect

        case (.drivingExperience(var childState), .drivingExperience(let childAction)):
            let effect = drivingExperienceReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.drivingExperience($0)) }
            state.screen = .drivingExperience(childState)
            state.draft.drivingExperience = childState.answers
            if case .nextTapped = childAction, childState.answers.canProceed {
                state.move(to: .optionalDrivingPreference)
            }
            return effect

        case (.optionalDrivingPreference(var childState), .optionalDrivingPreference(let childAction)):
            let effect = optionalPreferenceReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.optionalDrivingPreference($0)) }
            state.screen = .optionalDrivingPreference(childState)
            state.draft.preferences = childState.preferences

            switch childAction {
            case .skipTapped:
                return startSubmission(drivingGoal: "", state: &state)
            case .nextTapped(let goal) where childState.preferences.canProceed:
                return startSubmission(drivingGoal: goal, state: &state)
            default:
                return effect
            }

        case (.safety(var childState), .safety(let childAction)):
            let effect = safetyReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.safety($0)) }
            state.screen = .safety(childState)
            state.draft.agreedSafetyItems = childState.agreedSafetyItems
            if case .nextTapped = childAction, childState.isAllSafetyAgreed {
                state.move(to: .locationPermission)
            }
            return effect

        case (.locationPermission(var childState), .locationPermission(let childAction)):
            let effect = locationPermissionReducer.reduce(&childState, with: childAction)
                .map { Action.screen(OnboardingScreenAction.locationPermission($0)) }
            state.screen = .locationPermission(childState)
            if case .continueTapped = childAction {
                state.didComplete = true
            }
            return effect

        default:
            assertionFailure("Onboarding route and screen action do not match")
            return .none
        }
    }

    func reduceEntry(_ action: OnboardingEntryReducer.Action, state: inout State) {
        switch action {
        case .debugOnboardingTapped:
            state.debugOnboardingRequestID += 1
        case .browseTapped:
            state.draft.isBrowseUser = true
            state.draft.loginProvider = nil
            state.presentation = nil
            state.move(to: .terms)
        case .authenticationSucceeded(let provider, let isNewMember, let nickname):
            state.presentation = nil
            state.draft.isBrowseUser = false
            state.draft.loginProvider = provider
            state.draft.nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if isNewMember {
                state.move(to: .terms)
            } else {
                state.didComplete = true
            }
        case .authenticationFailed(let message):
            state.presentation = .loginFailure(message)
        case .withdrawalRecoveryRequired(let recovery):
            state.presentation = .withdrawal(.restore(recovery))
        case .withdrawalRestoreLocked(let date):
            state.presentation = .withdrawal(.rejoinLocked(rejoinAvailableAt: date))
        case .authenticationCancelled:
            state.presentation = nil
        case .onKakaoLoginTapped, .onAppleLoginTapped, .restoreTapped, .openedURL:
            state.presentation = nil
        }
    }

    func reducePresentation(
        _ action: Action.PresentationAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .dismissLoginFailure, .dismissWithdrawal:
            state.presentation = nil
            return .none
        case .restoreWithdrawal(let recovery):
            state.presentation = nil
            return reduceScreen(.entry(.restoreTapped(recovery)), state: &state)
        case .analysisCompletionConfirmed:
            state.presentation = nil
            state.move(to: .safety)
            return .none
        case .dismissSnackbar:
            if case .snackbar = state.presentation {
                state.presentation = nil
            }
            return .none
        }
    }

    func startSubmission(drivingGoal: String, state: inout State) -> Effect<Action> {
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
            .init(result: analysis, recentFrequency: state.draft.drivingExperience.recentDrivingFrequency)
        )

        return .run { send in
            let startedAt = Date()
            let outcome: SubmissionOutcome

            if isDebugTesting {
                outcome = .completed
            } else {
                do {
                    try await memberRepository.submitOnboarding(submission)
                    outcome = .completed
                } catch let error as NetworkError {
                    outcome = Self.submissionOutcome(for: error)
                } catch {
                    outcome = .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
                }
            }

            let remaining = max(0, 3 - Date().timeIntervalSince(startedAt))
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            await send(.submissionFinished(outcome))
        }
    }

    func reduceSubmission(_ outcome: SubmissionOutcome, state: inout State) -> Effect<Action> {
        switch outcome {
        case .completed:
            guard case .analyzing(let analysis) = state.presentation else { return .none }
            state.presentation = .analysisComplete(analysis)
            return .none
        case .failed(let message):
            state.presentation = .snackbar(message)
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                await send(.presentation(.dismissSnackbar))
            }
        }
    }

    static func submissionOutcome(for error: NetworkError) -> SubmissionOutcome {
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

    func persistDraftIfNeeded(for state: State) {
        guard persistsDraft,
              let provider = state.draft.loginProvider,
              !state.draft.isBrowseUser,
              !state.didComplete
        else { return }
        draftStore.save(state.draft.payload(route: state.route, provider: provider))
    }
}

enum OnboardingScreenState {
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
        case .entry:
            .entry(.init(recentLoginProvider: recentLoginProvider))
        case .terms:
            .terms(.init(agreedTerms: draft.agreedTerms))
        case .nickname:
            .nickname(.init(nickname: draft.nickname))
        case .drivingExperience:
            .drivingExperience(.init(answers: draft.drivingExperience))
        case .optionalDrivingPreference:
            .optionalDrivingPreference(.init(preferences: draft.preferences))
        case .safety:
            .safety(.init(agreedSafetyItems: draft.agreedSafetyItems))
        case .locationPermission:
            .locationPermission(.init())
        }
    }
}

enum OnboardingScreenAction {
    case entry(OnboardingEntryReducer.Action)
    case terms(OnboardingTermsReducer.Action)
    case nickname(OnboardingNicknameReducer.Action)
    case drivingExperience(OnboardingDrivingExperienceReducer.Action)
    case optionalDrivingPreference(OnboardingOptionalDrivingPreferenceReducer.Action)
    case safety(OnboardingSafetyReducer.Action)
    case locationPermission(OnboardingLocationPermissionReducer.Action)
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
