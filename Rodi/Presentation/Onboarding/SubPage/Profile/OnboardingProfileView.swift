//
//  OnboardingProfileView.swift
//  Rodi
//

import SwiftUI

struct OnboardingProfileView: View {
    @StateObject private var store: StoreOf<OnboardingProfileReducer>
    private let onTransition: (OnboardingTransition) -> Void

    init(
        session: OnboardingSession,
        screen: OnboardingProfileReducer.State.Screen,
        onTransition: @escaping (OnboardingTransition) -> Void,
        memberRepository: MemberRepository
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: .init(
                    session: session,
                    screen: screen
                ),
                reducer: OnboardingProfileReducer(memberRepository: memberRepository)
            )
        )
        self.onTransition = onTransition
    }

    var body: some View {
        OnboardingContainer(step: step) {
            content
        } onBack: {
            store.send(.backTapped)
        }
        .overlay { presentationOverlay }
        .rodiSnackbar(message: snackbarMessage)
        .onChange(of: store.state.transition) { transition in
            guard let transition else { return }
            onTransition(transition)
            store.send(.transitionConsumed)
        }
    }
}

private extension OnboardingProfileView {
    @ViewBuilder
    var content: some View {
        switch store.state.screen {
        case .nickname: NicknameView(state: store.state, send: store.send)
        case .drivingExperience: DrivingExperienceView(state: store.state, send: store.send)
        case .drivingPreference: DrivingPreferenceView(state: store.state, send: store.send)
        }
    }

    var step: OnboardingStep {
        switch store.state.screen {
        case .nickname: .nickname
        case .drivingExperience: .drivingExperience
        case .drivingPreference: .optionalDrivingPreference
        }
    }

    @ViewBuilder
    var presentationOverlay: some View {
        switch store.state.presentation {
        case .analyzing:
            OnboardingAnalysisDialog()
        case .analysisComplete(let presentation):
            OnboardingAnalysisCompletionDialog(
                analysis: presentation.result,
                recentFrequency: presentation.recentFrequency,
                onConfirm: { store.send(.analysisConfirmed) }
            )
        case .none, .snackbar:
            EmptyView()
        }
    }

    var snackbarMessage: String? {
        if case .snackbar(let message) = store.state.presentation { return message }
        return nil
    }
}
