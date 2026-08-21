//
//  PracticeTrackingView.swift
//  Rodi
//

import SwiftUI

/// 연습 추적 Feature의 lifecycle adapter와 연속 측정 dialog를 조립한다.
struct PracticeTrackingView: View {
    let state: PracticeTrackingReducer.State
    let canPresentReviewPrompt: Bool
    @ObservedObject var service: PracticeTrackingService
    let send: (PracticeTrackingReducer.Action) -> Void

    var body: some View {
        ZStack {
            PracticeTrackingLifecycleHost(
                service: service,
                certificationChanged: {
                    send(.certificationRevisionChanged(
                        canPresentPrompt: canPresentReviewPrompt
                    ))
                }
            )

            if let measurement = state.practiceReturn.activeMeasurementContinuation {
                PracticeTrackingContinuationDialog(
                    courseName: measurement.placeName,
                    continueAction: { send(.activeMeasurementContinued) },
                    endAction: { send(.activeMeasurementEnded) }
                )
            }
        }
    }
}
