//
//  DrivePracticeView.swift
//  Rodi
//

import SwiftUI

struct DrivePracticeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var service: DrivePracticeService
    
    let state: DrivePracticeReducer.State
    let canPresentReviewPrompt: Bool
    let send: (DrivePracticeReducer.Action) -> Void
    
    var body: some View {
        ZStack {
            if let measurement = state.activeMeasurementContinuation {
                DrivePracticeContinuationDialog(
                    courseName: measurement.placeName,
                    continueAction: { send(.activeMeasurementContinued) },
                    endAction: { send(.activeMeasurementEnded) }
                )
            }
        }
        .onReceive(service.$certificationRevision) { _ in
            guard scenePhase == .active else { return }
            send(.certificationRevisionChanged(canPresentPrompt: canPresentReviewPrompt))
        }

    }
}
