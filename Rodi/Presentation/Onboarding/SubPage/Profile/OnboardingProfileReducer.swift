//
//  OnboardingProfileReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct OnboardingProfileReducer: Reducer {
    struct State {
        enum Screen { case nickname, drivingExperience, drivingPreference }
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

        init(session: OnboardingSession, screen: Screen) {
            self.screen = screen
            self.session = session
            nickname = session.nickname ?? ""
            drivingExperience = session.drivingExperience ?? .init()
            preferences = session.preferences ?? .init()
            drivingGoal = session.drivingGoal ?? ""
        }

        var canProceedFromNickname: Bool { !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    enum Action {
        case nicknameChanged(String)
        case nicknameNextTapped
        case selectLicenseDrivingPeriod(LicenseDrivingPeriod)
        case selectRecentDrivingFrequency(RecentDrivingFrequency)
        case toggleRoadDrivingExperience(RoadDrivingExperience)
        case selectSoloDrivingRange(SoloDrivingRange)
        case selectSoloParkingLevel(SoloParkingLevel)
        case drivingExperienceNextTapped
        case togglePracticeSituation(PracticeSituation)
        case selectVehicleType(VehicleType)
        case drivingGoalChanged(String)
        case preferenceSkipTapped
        case preferenceNextTapped
        case analysisConfirmed
        case submissionCompleted(SubmissionOutcome)
        case dismissSnackbar
        case backTapped
        case transitionConsumed
    }

    private enum EffectID { case submission, snackbar }
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .nicknameChanged(let nickname):
            state.nickname = nickname

        case .nicknameNextTapped:
            guard state.canProceedFromNickname else { return .none }
            state.session.nickname = state.nickname
            track("nickname", session: state.session)
            state.transition = .init(updatedSession: state.session, navigation: .push(.drivingExperience))

        case .selectLicenseDrivingPeriod(let period): state.drivingExperience.licenseDrivingPeriod = period
        case .selectRecentDrivingFrequency(let frequency): state.drivingExperience.recentDrivingFrequency = frequency
        case .toggleRoadDrivingExperience(let experience): toggleRoadDrivingExperience(experience, answers: &state.drivingExperience)
        case .selectSoloDrivingRange(let range): state.drivingExperience.soloDrivingRange = range
        case .selectSoloParkingLevel(let level): state.drivingExperience.soloParkingLevel = level

        case .drivingExperienceNextTapped:
            guard state.drivingExperience.canProceed else { return .none }
            state.session.drivingExperience = state.drivingExperience
            track("driving_experience", session: state.session)
            state.transition = .init(updatedSession: state.session, navigation: .push(.optionalDrivingPreference))

        case .togglePracticeSituation(let situation):
            if let index = state.preferences.selectedPracticeSituations.firstIndex(of: situation) {
                state.preferences.selectedPracticeSituations.remove(at: index)
            } else if state.preferences.selectedPracticeSituations.count < 3 {
                state.preferences.selectedPracticeSituations.append(situation)
            }

        case .selectVehicleType(let type): state.preferences.vehicleType = type
        case .drivingGoalChanged(let goal): state.drivingGoal = goal

        case .preferenceSkipTapped:
            return submit(session: completedSession(state: state, drivingGoal: ""), state: &state)

        case .preferenceNextTapped:
            guard state.preferences.canProceed else { return .none }
            return submit(session: completedSession(state: state, drivingGoal: state.drivingGoal), state: &state)

        case .submissionCompleted(let outcome):
            return finishSubmission(outcome, state: &state)

        case .analysisConfirmed:
            state.presentation = nil
            state.transition = .init(updatedSession: state.session, navigation: .push(.safety))

        case .dismissSnackbar:
            if case .snackbar = state.presentation { state.presentation = nil }

        case .backTapped:
            state.transition = .init(updatedSession: currentSession(state), navigation: .pop)

        case .transitionConsumed:
            state.transition = nil
        }
        return .none
    }
}

private extension OnboardingProfileReducer {
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
            await send(.submissionCompleted(outcome))
        }.cancelTask(id: EffectID.submission)
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
            .failed("네트워크 연결을 확인한 뒤 다시 시도해 주세요.")
        case .httpStatusCode(let code) where code >= 500,
             .apiError(_, _, let code?) where code >= 500:
            .failed("서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
        case .httpStatusCode(let code) where (400..<500).contains(code),
             .apiError(_, _, let code?) where (400..<500).contains(code):
            .completed
        default:
            .failed("온보딩 정보를 저장하지 못했어요. 다시 시도해 주세요.")
        }
    }

    func track(_ step: String, session: OnboardingSession) {
        RodiAnalytics.track(.onboardingStepCompleted(step: step, entryMode: session.entryMode))
    }

    func toggleRoadDrivingExperience(_ experience: RoadDrivingExperience, answers: inout OnboardingDrivingExperience) {
        if experience == .none {
            answers.selectedRoadDrivingExperiences = answers.selectedRoadDrivingExperiences == [.none] ? [] : [.none]
        } else if let index = answers.selectedRoadDrivingExperiences.firstIndex(of: experience) {
            answers.selectedRoadDrivingExperiences.remove(at: index)
        } else {
            answers.selectedRoadDrivingExperiences.removeAll { $0 == .none }
            answers.selectedRoadDrivingExperiences.append(experience)
        }
        if !answers.selectedRoadDrivingExperiences.contains(.soloPractice) {
            answers.soloDrivingRange = nil
            answers.soloParkingLevel = nil
        }
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
