//
//  OnboardingView.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @StateObject var onboardingStore: StoreOf<OnboardingReducer>
    @State var locationPermission: LocationPermissionRequester

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _onboardingStore = StateObject(wrappedValue: Store(state: OnboardingState(), reducer: OnboardingReducer()))
        _locationPermission = State(initialValue: LocationPermissionRequester())
    }

    init(
        onComplete: @escaping () -> Void,
        onboardingStore: StoreOf<OnboardingReducer>,
        locationPermission: LocationPermissionRequester
    ) {
        self.onComplete = onComplete
        _onboardingStore = StateObject(wrappedValue: onboardingStore)
        _locationPermission = State(initialValue: locationPermission)
    }

    var body: some View {
        OnboardingContainer(step: onboardingStore.state.step) {
            onboardingStepView
        } onBack: {
            onboardingStore.send(.navigation(.backTapped))
        }
        .sheet(item: selectedTermsPageBinding) { terms in
            LegalWebView(title: terms.title, url: terms.url)
        }
        .onChange(of: onboardingStore.state.didComplete) { didComplete in
            guard didComplete else { return }
            onComplete()
        }
    }

    @ViewBuilder
    private var onboardingStepView: some View {
        switch onboardingStore.state.step {
            case .locationPermission:
                LocationPermissionView(onAllow: requestLocationPermission)
            
            case .terms:
                TermsAgreementView(
                    agreedTerms: onboardingStore.state.agreedTerms,
                    isAllAgreed: onboardingStore.state.isAllTermsAgreed,
                    onToggleAll: { onboardingStore.send(.terms(.toggleAll)) },
                    onToggleTerms: { onboardingStore.send(.terms(.toggle($0))) },
                    onOpenTerms: { onboardingStore.send(.terms(.open($0))) },
                    onNext: { onboardingStore.send(.terms(.nextTapped)) }
                )
            
            case .safety:
                SafetyAgreementView(
                    agreedSafetyItems: onboardingStore.state.agreedSafetyItems,
                    isAllAgreed: onboardingStore.state.isAllSafetyAgreed,
                    onToggleSafety: { onboardingStore.send(.safety(.toggle($0))) },
                    onNext: { onboardingStore.send(.safety(.finishTapped)) }
                )
        }
    }
}
