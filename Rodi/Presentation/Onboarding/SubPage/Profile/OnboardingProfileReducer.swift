//
//  OnboardingProfileReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct OnboardingProfileReducer: Reducer {
    struct State {
        enum Screen { case nickname, drivingExperience, drivingPreference }
        enum FormLoadState: Equatable { case idle, loading, loaded, failed(String) }
        enum Presentation: Equatable {
            case analyzing(OnboardingProfileAnalysisPresentation)
            case analysisComplete(OnboardingProfileAnalysisPresentation)
            case snackbar(String)
        }

        var screen: Screen
        var session: OnboardingSession
        var nickname: String
        var drivingExperience: OnboardingDrivingExperience
        var preferences: OnboardingDrivingPreferences
        var drivingGoal: String
        var presentation: Presentation?
        var transition: OnboardingTransition?
        var formLoadState: FormLoadState = .idle
        var requestID = 0
        var isActive = true

        init(session: OnboardingSession, screen: Screen) {
            self.screen = screen
            self.session = session
            nickname = session.nickname ?? ""
            drivingExperience = session.drivingExperience ?? .init()
            preferences = session.preferences ?? .init()
            drivingGoal = session.drivingGoal ?? ""
            if session.form != nil { formLoadState = .loaded }
        }

        var canProceedFromNickname: Bool { !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var formAnswers: [MemberOnboardingForm.Field: [String]] {
            OnboardingFormAnswerAdapter.values(experience: drivingExperience, preferences: preferences, goal: drivingGoal)
        }
        var formStep: MemberOnboardingForm.Step? {
            session.form?.step(isExperience: screen == .drivingExperience)
        }
        var visibleQuestions: [MemberOnboardingForm.Question] {
            guard let form = session.form, let step = formStep else { return [] }
            return form.visibleQuestions(in: step, answers: formAnswers)
        }
        var canProceedFromForm: Bool {
            guard formLoadState == .loaded, presentation == nil, let form = session.form, let step = formStep else { return false }
            if screen == .drivingPreference, let experience = form.step(isExperience: true),
               !form.canProceed(in: experience, answers: formAnswers) { return false }
            return form.canProceed(in: step, answers: formAnswers)
        }
    }

    enum Action {
        case appeared
        case sessionRestored(OnboardingSession)
        case disappeared
        case retryFormTapped
        case formLoaded(Result<MemberOnboardingForm, NetworkError>, requestID: Int)
        case selectFormOption(MemberOnboardingForm.Field, String)
        case nicknameChanged(String)
        case nicknameNextTapped
        case drivingExperienceNextTapped
        case drivingGoalChanged(String)
        case preferenceSkipTapped
        case preferenceNextTapped
        case analysisConfirmed
        case submissionCompleted(SubmissionOutcome, requestID: Int)
        case dismissSnackbar
        case backTapped
        case transitionConsumed
    }

    private enum EffectID { case work, snackbar }
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .sessionRestored(let session):
            guard !state.isActive else { return .none }
            let cachedForm = session.form ?? state.session.form
            state.session = session
            state.session.form = cachedForm
            state.nickname = session.nickname ?? ""
            state.drivingExperience = session.drivingExperience ?? .init()
            state.preferences = session.preferences ?? .init()
            state.drivingGoal = session.drivingGoal ?? ""
            state.formLoadState = cachedForm == nil ? .idle : .loaded
            if cachedForm != nil { applyAnswers(state.formAnswers, state: &state) }

        case .appeared:
            state.isActive = true
            guard state.screen != .nickname, !state.session.isGuest,
                  state.formLoadState == .idle else { return .none }
            return loadForm(state: &state)

        case .retryFormTapped:
            guard state.isActive, state.screen != .nickname, !state.session.isGuest,
                  case .failed = state.formLoadState else { return .none }
            return loadForm(state: &state)

        case .formLoaded(let result, let requestID):
            guard state.isActive, state.requestID == requestID, state.formLoadState == .loading else { return .none }
            switch result {
            case .success(let form):
                state.session.form = form
                state.formLoadState = .loaded
                applyAnswers(state.formAnswers, state: &state)
            case .failure(.cancel): state.formLoadState = .idle
            case .failure(let error):
                state.formLoadState = .failed(Self.formErrorMessage(error))
            }

        case .disappeared:
            state.isActive = false
            state.requestID += 1
            if state.formLoadState == .loading { state.formLoadState = .idle }
            if case .analyzing = state.presentation { state.presentation = nil }
            return .cancel(id: EffectID.work)

        case .selectFormOption(let field, let code):
            guard state.isActive, state.presentation == nil,
                  let question = state.visibleQuestions.first(where: { $0.id == field }),
                  let option = question.options.first(where: { $0.id == code }) else { return .none }
            var answers = state.formAnswers
            var values = answers[field] ?? []
            if question.kind == .single { values = [code] }
            else if values.contains(code) { values.removeAll { $0 == code } }
            else if option.exclusive { values = [code] }
            else {
                values.removeAll { value in question.options.contains { $0.id == value && $0.exclusive } }
                guard question.maxSelect.map({ values.count < $0 }) ?? true else { return .none }
                values.append(code)
            }
            answers[field] = values
            applyAnswers(answers, state: &state)

        case .nicknameChanged(let nickname):
            state.nickname = nickname

        case .nicknameNextTapped:
            guard state.canProceedFromNickname else { return .none }
            state.session.nickname = state.nickname
            track("nickname", session: state.session)
            state.transition = .init(updatedSession: state.session, navigation: .push(.drivingExperience))

        case .drivingExperienceNextTapped:
            guard state.canProceedFromForm else { return .none }
            state.session = currentSession(state)
            track("driving_experience", session: state.session)
            state.transition = .init(updatedSession: state.session, navigation: .push(.optionalDrivingPreference))

        case .drivingGoalChanged(let goal):
            guard state.presentation == nil, state.visibleQuestions.contains(where: { $0.id == .drivingGoal }) else { return .none }
            var answers = state.formAnswers
            answers[.drivingGoal] = [goal]
            applyAnswers(answers, state: &state)

        case .preferenceSkipTapped:
            guard state.formLoadState == .loaded, state.screen == .drivingPreference,
                  state.formStep?.skippable == true, state.presentation == nil,
                  let form = state.session.form, let experience = form.step(isExperience: true),
                  form.canProceed(in: experience, answers: state.formAnswers) else { return .none }
            var session = currentSession(state)
            session.preferences = .init()
            session.drivingGoal = ""
            return submit(session: session, state: &state)

        case .preferenceNextTapped:
            guard state.canProceedFromForm else { return .none }
            return submit(session: completedSession(state: state, drivingGoal: state.drivingGoal), state: &state)

        case .submissionCompleted(let outcome, let requestID):
            guard state.isActive, state.requestID == requestID else { return .none }
            return finishSubmission(outcome, state: &state)

        case .analysisConfirmed:
            state.presentation = nil
            state.transition = .init(updatedSession: state.session, navigation: .push(.safety))

        case .dismissSnackbar:
            if case .snackbar = state.presentation { state.presentation = nil }

        case .backTapped:
            guard state.presentation == nil else { return .none }
            state.transition = .init(updatedSession: currentSession(state), navigation: .pop)

        case .transitionConsumed:
            state.transition = nil
        }
        return .none
    }
}

private extension OnboardingProfileReducer {
    func loadForm(state: inout State) -> Effect<Action> {
        state.formLoadState = .loading
        state.requestID += 1
        let requestID = state.requestID
        let repository = memberRepository
        return .run { send in
            let result: Result<MemberOnboardingForm, NetworkError>
            do { result = .success(try await repository.fetchOnboardingForm()) }
            catch let error as NetworkError { result = .failure(error) }
            catch { result = .failure(.unknown(errorCode: "onboarding_form")) }
            guard !Task.isCancelled else { return }
            await send(.formLoaded(result, requestID: requestID))
        }.cancelTask(id: EffectID.work)
    }

    func applyAnswers(_ answers: [MemberOnboardingForm.Field: [String]], state: inout State) {
        guard let form = state.session.form else { return }
        let sanitized = OnboardingFormAnswerAdapter.sanitized(answers, form: form)
        OnboardingFormAnswerAdapter.apply(sanitized, experience: &state.drivingExperience, preferences: &state.preferences, goal: &state.drivingGoal)
    }

    static func formErrorMessage(_ error: NetworkError) -> String {
        switch error {
        case .networkUnavailable, .timeOut: "네트워크 연결을 확인해주세요."
        case .apiError(_, let message, _): message
        case .decodingFail: "온보딩 질문 정보를 확인할 수 없어요. 잠시 후 다시 시도해주세요."
        default: "온보딩 질문을 불러오지 못했어요. 다시 시도해주세요."
        }
    }

    func currentSession(_ state: State) -> OnboardingSession {
        var session = state.session
        session.nickname = state.nickname
        session.drivingExperience = state.drivingExperience
        session.preferences = state.preferences
        session.drivingGoal = state.drivingGoal
        return session
    }

    func completedSession(state: State, drivingGoal: String) -> OnboardingSession {
        var session = currentSession(state)
        session.drivingGoal = drivingGoal
        return session
    }

    func submit(session: OnboardingSession, state: inout State) -> Effect<Action> {
        guard let experience = session.drivingExperience,
              let preferences = session.preferences,
              let submission = OnboardingSubmissionMapper.make(drivingExperience: experience, preferences: preferences, drivingGoal: session.drivingGoal ?? "")
        else { return .none }

        state.session = session
        let analysis = MemberOnboardingLevelPolicy.analyze(submission)
        state.presentation = .analyzing(.init(result: analysis, recentFrequency: experience.recentDrivingFrequency))
        track("optional_driving_preference", session: session)
        let repository = memberRepository
        state.requestID += 1
        let requestID = state.requestID

        return .run { send in
            let startedAt = Date()
            let outcome: SubmissionOutcome
            do {
                try await repository.submitOnboarding(submission)
                outcome = .completed
            } catch let error as NetworkError {
                outcome = Self.submissionOutcome(for: error)
            } catch {
                outcome = .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
            }
            let remaining = max(0, 3 - Date().timeIntervalSince(startedAt))
            if remaining > 0 { try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000)) }
            guard !Task.isCancelled else { return }
            await send(.submissionCompleted(outcome, requestID: requestID))
        }.cancelTask(id: EffectID.work)
    }

    func finishSubmission(_ outcome: SubmissionOutcome, state: inout State) -> Effect<Action> {
        switch outcome {
        case .completed:
            if case .analyzing(let analysis) = state.presentation { state.presentation = .analysisComplete(analysis) }
            return .none
        case .failed(let message):
            state.presentation = .snackbar(message)
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await send(.dismissSnackbar)
            }.cancelTask(id: EffectID.snackbar)
        }
    }

    static func submissionOutcome(for error: NetworkError) -> SubmissionOutcome {
        switch error {
        case .networkUnavailable, .timeOut:
            .failed("네트워크 연결을 확인해주세요.")
        case .httpStatusCode(let code) where code >= 500,
             .apiError(_, _, let code?) where code >= 500:
            .failed("서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
        case .apiError(_, let message, _):
            .failed(message)
        default:
            .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
        }
    }

    func track(_ step: String, session: OnboardingSession) {
        RodiAnalytics.track(.onboardingStepCompleted(step: step, entryMode: session.entryMode))
    }

}

struct OnboardingProfileAnalysisPresentation: Equatable {
    let result: MemberOnboardingAnalysis
    let recentFrequency: RecentDrivingFrequency?
}

enum SubmissionOutcome: Equatable {
    case completed
    case failed(String)
}
