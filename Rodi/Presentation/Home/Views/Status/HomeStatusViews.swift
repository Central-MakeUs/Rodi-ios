//
//  HomeStatusViews.swift
//  Rodi
//

import SwiftUI

struct HomeStatusOverlay: View {
    let state: HomeOverlayState
    let retryAction: () -> Void

    var body: some View {
        ZStack {
            RodiColor.white.ignoresSafeArea()

            switch state {
            case .loading(let kind):
                MapLoadingContent(kind: kind)
            case .networkUnavailable:
                NetworkUnavailableContent(retryAction: retryAction)
            case .mapUnavailable(let message):
                MapUnavailableContent(message: message)
            }
        }
    }
}
