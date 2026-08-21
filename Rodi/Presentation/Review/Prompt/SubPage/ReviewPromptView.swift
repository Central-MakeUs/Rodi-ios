import SwiftUI

struct ReviewPromptView: View {
    let state: ReviewPromptReducer.State
    let send: (ReviewPromptReducer.Action) -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog {
                VStack(spacing: 0) {
                    Text("‘\(state.target?.placeName ?? "")’")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.primary)
                    
                    Text("연습은 잘 다녀오셨나요?")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                        .padding(.top, 4)
                    
                    Text("연습 기록을 남겨 늘어나는 실력을\n한눈에 확인해보세요.")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)

                    HStack(spacing: 8) {
                        ReviewDialogButton(title: "안 했어요", isPrimary: false) {
                            send(.notVisitedTapped)
                        }
                        .disabled(state.isVisitSubmitting)
                        
                        ReviewDialogButton(title: "다녀왔어요", isPrimary: true) {
                            send(.visitedTapped)
                        }
                        .disabled(state.isVisitSubmitting)
                    }
                    .padding(.top, 24)
            }
        } closeAction: {
            guard !state.isVisitSubmitting else { return }
            send(.closeTapped)
        }
        }
    }
}
