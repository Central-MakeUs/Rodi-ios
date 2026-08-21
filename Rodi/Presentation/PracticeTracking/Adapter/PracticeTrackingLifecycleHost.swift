//
//  PracticeTrackingLifecycleHost.swift
//  Rodi
//

import SwiftUI

/// App 수명주기와 추적 service의 runtime event를 feature Action으로 변환한다.
struct PracticeTrackingLifecycleHost: View {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var service: PracticeTrackingService
    let certificationChanged: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onReceive(service.$certificationRevision) { _ in
                guard scenePhase == .active else { return }
                certificationChanged()
            }
    }
}
