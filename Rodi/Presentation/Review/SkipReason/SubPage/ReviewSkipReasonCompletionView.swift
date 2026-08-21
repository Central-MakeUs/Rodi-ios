import SwiftUI

struct ReviewSkipReasonCompletionView: View {
    let send: (ReviewSkipReasonReducer.Action) -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("소중한 의견 감사해요!")
                            .rodiTypography(.body1SemiBold)
                            .foregroundStyle(RodiColor.black)

                        Text("남겨주신 내용은 코스 탐색 경험을\n개선하는 데 활용할게요 :)")
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
