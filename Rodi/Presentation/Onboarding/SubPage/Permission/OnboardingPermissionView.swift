//
//  OnboardingPermissionView.swift
//  Rodi
//

import SwiftUI

struct OnboardingPermissionView: View {
    @StateObject private var store: StoreOf<OnboardingPermissionReducer>
    private let onTransition: (OnboardingTransition) -> Void

    init(
        session: OnboardingSession,
        screen: OnboardingPermissionReducer.State.Screen,
        onTransition: @escaping (
            OnboardingTransition
        ) -> Void
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: .init(
                    session: session,
                    screen: screen
                ),
                reducer: OnboardingPermissionReducer()
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
        .onChange(of: store.state.transition) { transition in
            guard let transition else { return }
            onTransition(transition)
            store.send(.transitionConsumed)
        }
    }
}

private extension OnboardingPermissionView {
    @ViewBuilder
    var content: some View {
        switch store.state.screen {
        case .safety: SafetyView(state: store.state, send: store.send)
        case .locationPermission: LocationPermissionView(send: store.send)
        }
    }

    var step: OnboardingStep {
        switch store.state.screen {
        case .safety: .safety
        case .locationPermission: .locationPermission
        }
    }
}
