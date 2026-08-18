import SwiftUI

struct ReviewDiscardConfirmationView<Action>: View {
    let send: (Action) -> Void
    let confirmAction: Action
    let cancelAction: Action

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("작성 중인 화면을 나갈까요?")
                            .rodiTypography(.body1SemiBold)
                            .foregroundStyle(RodiColor.black)
                        
                        Text("나가면 입력한 내용이 저장되지 않아요.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                    }
                HStack(spacing: 8) {
                    ReviewDialogButton(title: "나가기", isPrimary: false) {
                        send(confirmAction)
                    }
                    ReviewDialogButton(title: "계속 작성", isPrimary: true) {
                        send(cancelAction)
                    }
                }
                .padding(.top, 24)
                }
            }
        }
    }
}
