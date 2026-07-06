//
//  HomeFloatingControlLayer.swift
//  Rodi
//

import SwiftUI

struct HomeFloatingControlLayer: View {
    let isCurrentLocationActive: Bool
    let bottomInset: CGFloat
    let opacity: CGFloat
    let allowsHitTesting: Bool
    let isAccessibilityHidden: Bool
    let spacing: CGFloat
    let legalSettingsAction: () -> Void
    let currentLocationAction: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                LegalSettingsButton(action: legalSettingsAction)
                    .padding(.leading, spacing)

                Spacer()

                CurrentLocationButton(
                    isActive: isCurrentLocationActive,
                    action: currentLocationAction
                )
                .padding(.trailing, spacing)
            }
            .padding(.bottom, bottomInset)
        }
        .opacity(opacity)
        .allowsHitTesting(allowsHitTesting)
        .accessibilityHidden(isAccessibilityHidden)
        .zIndex(2)
    }
}
