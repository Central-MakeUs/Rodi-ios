import SwiftUI

struct ActiveCourseMeasurementDialog: View {
    let courseName: String
    let continueAction: () -> Void
    let endAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog {
                VStack(spacing: 0) {
                    Text("‘\(courseName)’")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.primary)
                    Text("아직 코스를 연습 중이신가요?")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                        .padding(.top, 4)
                    Text("코스 주행을 이어서 측정할까요?")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    HStack(spacing: 8) {
                        ReviewDialogButton(title: "측정 종료", isPrimary: false, action: endAction)
                        ReviewDialogButton(title: "계속 측정", isPrimary: true, action: continueAction)
                    }
                    .padding(.top, 24)
                }
            } closeAction: {
                continueAction()
            }
        }
    }
}
