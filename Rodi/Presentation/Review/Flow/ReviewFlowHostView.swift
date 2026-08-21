//
//  ReviewFlowHostView.swift
//  Rodi
//

import SwiftUI

struct ReviewFlowHostView: View {
    let state: ReviewFlowCoordinatorReducer.State
    let send: (ReviewFlowCoordinatorReducer.Action) -> Void

    var body: some View {
        if state.entrySource != .courseDetail {
            ReviewView(
                state: state.review,
                send: { send(.review($0)) }
            )
        }
    }
}
