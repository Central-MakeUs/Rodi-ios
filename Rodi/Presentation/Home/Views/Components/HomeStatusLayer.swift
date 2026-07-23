//
//  HomeStatusLayer.swift
//  Rodi
//

import SwiftUI

struct HomeStatusLayer: View {
    @ObservedObject var homeStore: StoreOf<HomeReducer>
    let retryAction: () -> Void

    var body: some View {
        if let overlayState = homeStore.state.overlayState {
            HomeStatusOverlay(
                state: overlayState,
                retryAction: retryAction
            )
            .zIndex(3)
        }
    }
}
