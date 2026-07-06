//
//  OnboardingView+Actions.swift
//  Rodi
//

import SwiftUI

extension OnboardingView {
    var selectedTermsPageBinding: Binding<TermsAgreement?> {
        Binding(
            get: { onboardingStore.state.selectedTermsPage },
            set: { onboardingStore.send(.presentation(.setTermsSheet(isPresented: $0 != nil))) }
        )
    }

    func requestLocationPermission() {
        locationPermission.requestPermission()
        onboardingStore.send(.navigation(.locationPermissionContinueTapped))
    }
}
