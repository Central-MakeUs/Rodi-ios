//
//  OnboardingView.swift
//  Rodi
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var router: OnboardingRouter
    @StateObject private var store: StoreOf<OnboardingReducer>

    private let onComplete: () -> Void
    private let automaticLoginProvider: SocialLoginProvider?
    private let automaticLoginRequestConsumed: () -> Void

    @MainActor
    init(
        onComplete: @escaping () -> Void,
        automaticLoginProvider: SocialLoginProvider? = nil,
        automaticLoginRequestConsumed: @escaping () -> Void = {}
    ) {
        let draftStore = OnboardingDraftStore()
        let recentLoginProviderStore = AuthDependencyContainer.shared.recentLoginProviderStore
        let payload = draftStore.load()
        let recentLoginProvider = recentLoginProviderStore.load()
        let initialRoute = OnboardingReducer.initialRoute(payload: payload)

        _router = StateObject(wrappedValue: OnboardingRouter(initialRoute: initialRoute))
        _store = StateObject(
            wrappedValue: Store(
                state: OnboardingReducer.State(
                    payload: payload,
                    initialRoute: initialRoute,
                    recentLoginProvider: recentLoginProvider
                ),
                reducer: OnboardingReducer(
                    draftStore: draftStore,
                    progressStore: OnboardingProgressStore(draftStore: draftStore),
                    persistsDraft: true
                )
            )
        )
        self.onComplete = onComplete
        self.automaticLoginProvider = automaticLoginProvider
        self.automaticLoginRequestConsumed = automaticLoginRequestConsumed
    }

    var body: some View {
        OnboardingContainer(step: router.route) {
            screenView
        } onBack: {
            guard let route = router.goBack() else { return }
            store.send(.routeChanged(route))
        }
        .alert("로그인에 실패했어요", isPresented: loginFailureBinding) {
            Button("확인") {
                store.send(.dismissLoginFailure)
            }
        } message: {
            Text(loginFailureMessage)
        }
        .rodiSnackbar(message: snackbarMessage)
        .overlay { presentationOverlay }
        .onOpenURL { url in
            store.send(.screen(route: router.route, action: .entry(.openedURL(url))))
        }
        .onAppear(perform: requestAutomaticLoginIfNeeded)
        .onChange(of: store.state.requestedRoute) { route in
            guard let route else { return }
            router.navigate(to: route)
            store.send(.routeChanged(route))
        }
        .onChange(of: store.state.didComplete) { didComplete in
            guard didComplete else { return }
            onComplete()
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch store.state.screen {
        case .entry(let state):
            OnboardingEntryView(state: state) {
                store.send(.screen(route: router.route, action: .entry($0)))
            }
        case .terms(let state):
            OnboardingTermsView(state: state) {
                store.send(.screen(route: router.route, action: .terms($0)))
            }
        case .nickname(let state):
            OnboardingNicknameView(state: state) {
                store.send(.screen(route: router.route, action: .nickname($0)))
            }
        case .drivingExperience(let state):
            OnboardingDrivingExperienceView(state: state) {
                store.send(.screen(route: router.route, action: .drivingExperience($0)))
            }
        case .optionalDrivingPreference(let state):
            OnboardingOptionalDrivingPreferenceView(state: state) {
                store.send(.screen(route: router.route, action: .optionalDrivingPreference($0)))
            }
        case .safety(let state):
            OnboardingSafetyView(state: state) {
                store.send(.screen(route: router.route, action: .safety($0)))
            }
        case .locationPermission:
            OnboardingLocationPermissionView {
                store.send(.screen(route: router.route, action: .locationPermission($0)))
            }
        }
    }

    @ViewBuilder
    private var presentationOverlay: some View {
        switch store.state.presentation {
        case .withdrawal(let state):
            WithdrawalAccountDialog(
                state: state,
                restoreAction: {
                    guard case .restore(let recovery) = state else { return }
                    store.send(.restoreWithdrawal(recovery))
                },
                dismissAction: { store.send(.dismissWithdrawal) }
            )
            .transition(.opacity)
        case .analyzing:
            OnboardingAnalysisDialog().transition(.opacity)
        case .analysisComplete(let presentation):
            OnboardingAnalysisCompletionDialog(
                analysis: presentation.result,
                recentFrequency: presentation.recentFrequency,
                onConfirm: { store.send(.analysisCompletionConfirmed) }
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
                if !isPresented { store.send(.dismissLoginFailure) }
            }
        )
    }

    private var loginFailureMessage: String {
        guard case .loginFailure(let message) = store.state.presentation else { return "" }
        return message
    }

    private var snackbarMessage: String? {
        guard case .snackbar(let message) = store.state.presentation else { return nil }
        return message
    }

    private func requestAutomaticLoginIfNeeded() {
        guard let automaticLoginProvider else { return }
        automaticLoginRequestConsumed()
        store.send(.automaticLoginRequested(automaticLoginProvider))
    }
}
