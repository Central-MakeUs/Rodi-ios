//
//  HomeStatusLayer.swift
//  Rodi
//

import SwiftUI

struct HomeStatusLayer: View {
    let overlayState: HomeOverlayState?
    let retryAction: () -> Void

    var body: some View {
        if let overlayState {
            HomeStatusOverlay(
                state: overlayState,
                retryAction: retryAction
            )
            .zIndex(3)
        }
    }
}
