import SwiftUI

struct CourseReviewBlockDialog: View {
    let state: CourseReviewBlockReducer.State
    let send: (CourseReviewBlockReducer.Action) -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("사용자를 차단하겠습니까?")
                            .rodiTypography(.body1SemiBold)
                            .foregroundStyle(RodiColor.black)

                        Text("이 사용자의 모든 리뷰를 보지 않습니다.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                    }
                    .frame(minWidth: 240)

                    HStack(spacing: 8) {
                        Button { send(.cancelTapped) } label: {
                            Text("취소")
                                .rodiTypography(.buttonMedium)
                                .foregroundStyle(RodiColor.gray800)
                                .frame(width: 116, height: 42)
                                .overlay { RoundedRectangle(cornerRadius: 8).stroke(RodiColor.gray300, lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                        .disabled(state.isBlocking)
                        .accessibilityLabel("차단 취소")

                        Button { send(.confirmTapped) } label: {
                            Group {
                                if state.isBlocking { ProgressView().controlSize(.small).tint(RodiColor.white) }
                                else { Text("차단").rodiTypography(.buttonMedium) }
                            }
                            .foregroundStyle(RodiColor.white)
                            .frame(width: 116, height: 42)
                            .background(RodiColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(state.isBlocking)
                        .accessibilityLabel("사용자 차단")
                    }
                    .padding(.top, 24)
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
