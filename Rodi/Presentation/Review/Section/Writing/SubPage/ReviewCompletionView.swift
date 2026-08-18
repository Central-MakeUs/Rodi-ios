import SwiftUI

struct ReviewCompletionView: View {
    let isEditing: Bool
    let send: (ReviewWritingReducer.Action) -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text(isEditing ? "후기 수정을 완료했어요!" : "후기 등록을 완료했어요!")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)

                    Text("오늘 남긴 기록이 나의 운전 여정에도,\n다른 운전자에게도 도움이 돼요.")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.black)
                        .multilineTextAlignment(.center)
                        .frame(height: 60)
                }
                .frame(minWidth: 240)

                Button(action: { send(.completionConfirmed) }) {
                    Text("확인")
                        .rodiTypography(.buttonMedium)
                        .foregroundStyle(RodiColor.white)
                        .frame(width: 116, height: 42)
                        .background(RodiColor.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
                }
            }
        }
    }
}
