import SwiftUI

struct ReviewFlowView: View {
    let state: ReviewReducer.State
    let send: (ReviewReducer.Action) -> Void

    var body: some View {
        Group {
            switch state.route {
            case .hidden:
                EmptyView()
            case .prompt:
                promptContent
            case .writing:
                writingContent
            case .skipReason:
                skipReasonContent
            }
        }
        .accessibilityAddTraits(state.isPresented ? .isModal : [])
    }
}

// MARK: - Section
private extension ReviewFlowView {

    @ViewBuilder
    var promptContent: some View {
        switch state.prompt.presentation {
        case .hidden:
            EmptyView()
        case .preparing:
            ReviewPreparingView()
        case .prompt:
            ReviewPromptView(
                state: state.prompt,
                send: { send(.prompt($0)) }
            )
        }
    }

    var writingContent: some View {
        ZStack {
            RodiColor.white
                .ignoresSafeArea()

            switch state.writing.page {
            case .hidden:
                EmptyView()
            case .loading:
                ProgressView()
                    .tint(RodiColor.primary)
            case .first:
                ReviewFormPageOneView(
                    state: state.writing,
                    send: { send(.writing($0)) }
                )
            case .second:
                ReviewFormPageTwoView(
                    state: state.writing,
                    send: { send(.writing($0)) }
                )
            }

            if state.writing.isDiscardConfirmationPresented {
                ReviewDiscardConfirmationView(
                    send: { send(.writing($0)) },
                    confirmAction: .discardConfirmed,
                    cancelAction: .discardCancelled
                )
            }

            if state.writing.isCompletionPresented {
                ReviewCompletionView(
                    isEditing: {
                        if case .edit = state.writing.mode { return true }
                        return false
                    }(),
                    send: { send(.writing($0)) }
                )
            }
        }
    }

    var skipReasonContent: some View {
        ZStack {
            RodiColor.white
                .ignoresSafeArea()

            ReviewSkipReasonView(
                state: state.skipReason,
                send: { send(.skipReason($0)) }
            )

            if state.skipReason.isDiscardConfirmationPresented {
                ReviewDiscardConfirmationView(
                    send: { send(.skipReason($0)) },
                    confirmAction: .discardConfirmed,
                    cancelAction: .discardCancelled
                )
            }

            if state.skipReason.isCompletionPresented {
                ReviewSkipReasonCompletionView(send: { send(.skipReason($0)) })
            }
        }
    }
}
