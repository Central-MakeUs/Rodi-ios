//
//  PracticeTrackingReducer.swift
//  Rodi
//

import Foundation

/// 연습 측정과 외부 길안내 복귀 후 정책을 하나의 Feature State로 소유한다.
struct PracticeTrackingReducer: Reducer {

    struct State {
        var practiceReturn = PracticeReturnReducer.State()
    }

    enum Action {
        case sceneBecameActive(canPresentPrompt: Bool)
        case sceneBecameInactive
        case certificationRevisionChanged(canPresentPrompt: Bool)
        case activeMeasurementContinued
        case activeMeasurementEnded
        case sessionEnded
        case promptInteractionRequested(PracticeReturnPromptInteraction)
        case practiceReturn(PracticeReturnReducer.Action)
        case delegate(Delegate)
    }

    enum Delegate {
        case reviewPromptRequested(PracticeReturnPrompt)
        case reviewPromptInteractionReady(PracticeReturnPromptInteraction)
        case reviewPromptVisitSubmissionChanged(Bool)
        case reviewFlowFinishedWithoutReview(String)
        case showSnackbar(String)
    }

    private let practiceReturnReducer: PracticeReturnReducer
    private let trackingService: PracticeTrackingService

    init(
        practiceRepository: PracticeRepository,
        measurementStore: PracticeMeasurementStoring,
        trackingService: PracticeTrackingService
    ) {
        self.trackingService = trackingService
        practiceReturnReducer = PracticeReturnReducer(
            practiceRepository: practiceRepository,
            measurementStore: measurementStore,
            trackingService: trackingService
        )
    }
}


// MARK: - Reduce
extension PracticeTrackingReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .sceneBecameActive(let canPresentPrompt),
             .certificationRevisionChanged(let canPresentPrompt):
            return reducePracticeReturn(
                &state,
                action: .sceneBecameActive(canPresentPrompt: canPresentPrompt)
            )

        case .sceneBecameInactive:
            return reducePracticeReturn(&state, action: .sceneBecameInactive)

        case .activeMeasurementContinued:
            return reducePracticeReturn(&state, action: .activeMeasurementContinued)

        case .activeMeasurementEnded:
            return reducePracticeReturn(&state, action: .activeMeasurementEnded)

        case .sessionEnded:
            trackingService.endForSessionChange()
            return reducePracticeReturn(&state, action: .reset)

        case .promptInteractionRequested(let interaction):
            return reducePracticeReturn(&state, action: .promptInteraction(interaction))

        case .practiceReturn(let action):
            return reducePracticeReturn(&state, action: action)

        case .delegate:
            return .none
        }
    }
}


// MARK: - Child Delegate
private extension PracticeTrackingReducer {

    func reducePracticeReturn(
        _ state: inout State,
        action: PracticeReturnReducer.Action
    ) -> Effect<Action> {
        if case .delegate(let delegate) = action {
            return reducePracticeReturnDelegate(delegate)
        }
        return practiceReturnReducer
            .reduce(&state.practiceReturn, with: action)
            .map(Action.practiceReturn)
    }

    func reducePracticeReturnDelegate(
        _ delegate: PracticeReturnReducer.Delegate
    ) -> Effect<Action> {
        switch delegate {
        case .promptRequested(let prompt):
            return .send(.delegate(.reviewPromptRequested(prompt)))

        case .reviewPromptInteraction(let interaction):
            return .send(.delegate(.reviewPromptInteractionReady(interaction)))

        case .reviewPromptVisitSubmissionChanged(let isSubmitting):
            return .send(.delegate(.reviewPromptVisitSubmissionChanged(isSubmitting)))

        case .finishedWithoutReview(let message):
            return .send(.delegate(.reviewFlowFinishedWithoutReview(message)))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }
}
