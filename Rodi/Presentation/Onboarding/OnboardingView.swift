//
//  OnboardingView.swift
//  Rodi
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var store: StoreOf<OnboardingReducer>

    enum Mode: Equatable {
        case production
        #if DEBUG
        case debugTesting
        #endif

        var persistsDraft: Bool {
            #if DEBUG
            self != .debugTesting
            #else
            true
            #endif
        }
    }

    private let onComplete: () -> Void
    private let onDebugOnboarding: () -> Void
    private let automaticLoginProvider: SocialLoginProvider?
    private let automaticLoginRequestConsumed: () -> Void

    @MainActor
    init(
        onComplete: @escaping () -> Void,
        mode: Mode = .production,
        onDebugOnboarding: @escaping () -> Void = {},
        automaticLoginProvider: SocialLoginProvider? = nil,
        automaticLoginRequestConsumed: @escaping () -> Void = {}
    ) {
        let draftStore = OnboardingDraftStore()
        let recentLoginProviderStore = AuthDependencyContainer.shared.recentLoginProviderStore
        #if DEBUG
        let isDebugTesting = mode == .debugTesting
        #else
        let isDebugTesting = false
        #endif

        _store = StateObject(
            wrappedValue: Store(
                state: OnboardingReducer.State(
                    draft: isDebugTesting ? nil : draftStore.load(),
                    recentLoginProvider: isDebugTesting ? nil : recentLoginProviderStore.load(),
                    isDebugTesting: isDebugTesting
                ),
                reducer: OnboardingReducer(
                    isDebugTesting: isDebugTesting,
                    memberRepository: AuthDependencyContainer.shared.memberRepository,
                    draftStore: draftStore,
                    persistsDraft: mode.persistsDraft
                )
            )
        )
        self.onComplete = onComplete
        self.onDebugOnboarding = onDebugOnboarding
        self.automaticLoginProvider = automaticLoginProvider
        self.automaticLoginRequestConsumed = automaticLoginRequestConsumed
    }

    var body: some View {
        OnboardingContainer(step: store.state.route) {
            screenView
        } onBack: {
            store.send(.navigation(.backTapped))
        }
        .alert("로그인에 실패했어요", isPresented: loginFailureBinding) {
            Button("확인") { store.send(.presentation(.dismissLoginFailure)) }
        } message: {
            Text(loginFailureMessage)
        }
        .rodiSnackbar(message: snackbarMessage)
        .overlay { overlay }
        .onOpenURL { store.send(.screen(.entry(.openedURL($0)))) }
        .onAppear(perform: requestAutomaticLoginIfNeeded)
        .onChange(of: store.state.didComplete) { didComplete in
            guard didComplete else { return }
            onComplete()
        }
        .onChange(of: store.state.debugOnboardingRequestID) { requestID in
            guard requestID > 0 else { return }
            onDebugOnboarding()
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch store.state.screen {
        case .entry(let state):
            OnboardingEntryView(state: state, send: { store.send(.screen(.entry($0))) })
        case .terms(let state):
            OnboardingTermsView(state: state, send: { store.send(.screen(.terms($0))) })
        case .nickname(let state):
            OnboardingNicknameView(state: state, send: { store.send(.screen(.nickname($0))) })
        case .drivingExperience(let state):
            OnboardingDrivingExperienceView(state: state, send: { store.send(.screen(.drivingExperience($0))) })
        case .optionalDrivingPreference(let state):
            OnboardingOptionalDrivingPreferenceView(
                state: state,
                send: { store.send(.screen(.optionalDrivingPreference($0))) }
            )
        case .safety(let state):
            OnboardingSafetyView(state: state, send: { store.send(.screen(.safety($0))) })
        case .locationPermission:
            OnboardingLocationPermissionView(send: { store.send(.screen(.locationPermission($0))) })
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch store.state.presentation {
        case .withdrawal(let state):
            WithdrawalAccountDialog(
                state: state,
                restoreAction: {
                    guard case .restore(let recovery) = state else { return }
                    store.send(.presentation(.restoreWithdrawal(recovery)))
                },
                dismissAction: { store.send(.presentation(.dismissWithdrawal)) }
            )
            .transition(.opacity)
        case .analyzing:
            OnboardingAnalysisDialog().transition(.opacity)
        case .analysisComplete(let presentation):
            OnboardingAnalysisCompletionDialog(
                analysis: presentation.result,
                recentFrequency: presentation.recentFrequency,
                onConfirm: { store.send(.presentation(.analysisCompletionConfirmed)) }
            )
            .transition(.opacity)
        case .none, .loginFailure, .snackbar:
            EmptyView()
        }
    }

    private var loginFailureBinding: Binding<Bool> {
        Binding(
            get: {
                if case .loginFailure = store.state.presentation { return true }
                return false
            },
            set: { isPresented in
                if !isPresented { store.send(.presentation(.dismissLoginFailure)) }
            }
        )
    }

    private var loginFailureMessage: String {
        if case .loginFailure(let message) = store.state.presentation {
            return message
        }
        return ""
    }

    private var snackbarMessage: String? {
        if case .snackbar(let message) = store.state.presentation {
            return message
        }
        return nil
    }

    private func requestAutomaticLoginIfNeeded() {
        guard let automaticLoginProvider else { return }
        automaticLoginRequestConsumed()
        store.send(.screen(.entry(
            automaticLoginProvider == .apple ? .onAppleLoginTapped : .onKakaoLoginTapped
        )))
    }
}
