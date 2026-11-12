//
//  OnboardingProfileView.swift
//  Rodi
//

import SwiftUI

struct OnboardingProfileView: View {
    @StateObject private var store: StoreOf<OnboardingProfileReducer>

    private let onTransition: (OnboardingTransition) -> Void
    private let incomingSession: OnboardingSession
    private let onFormLoaded: (MemberOnboardingForm) -> Void

    init(
        session: OnboardingSession,
        screen: OnboardingProfileReducer.State.Screen,
        onTransition: @escaping (OnboardingTransition) -> Void,
        memberRepository: MemberRepository,
        onFormLoaded: @escaping (MemberOnboardingForm) -> Void = { _ in }
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
        incomingSession = session
        self.onFormLoaded = onFormLoaded
    }

    var body: some View {
        OnboardingContainer(step: step) {
            content
        } onBack: {
            store.send(.backTapped)
        }
        .overlay { presentationOverlay }
        .rodiSnackbar(message: snackbarMessage)
        .onAppear {
            store.send(.sessionRestored(incomingSession))
            store.send(.appeared)
        }
        .onDisappear { store.send(.disappeared) }
        .onChange(of: store.state.session.form) { form in
            if let form { onFormLoaded(form) }
        }
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
        if store.state.screen == .nickname {
            NicknameView(
                state: store.state,
                send: store.send
            )
        } else {
            switch store.state.formLoadState {
            case .idle, .loading:
                VStack { Spacer(); ProgressView().accessibilityLabel("온보딩 질문 불러오는 중"); Spacer() }
                    .frame(maxWidth: .infinity)
            case .failed(let message):
                VStack(spacing: 16) {
                    Spacer()
                    Text(message).rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray600).multilineTextAlignment(.center)
                    Button { store.send(.retryFormTapped) } label: {
                        Text("다시 시도").rodiTypography(.body1SemiBold)
                            .padding(16).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Spacer()
                }.frame(maxWidth: .infinity).padding(.horizontal, 16)
            case .loaded:
                if store.state.screen == .drivingExperience {
                    DrivingExperienceView(state: store.state, send: store.send)
                } else {
                    DrivingPreferenceView(state: store.state, send: store.send)
                }
            }
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
