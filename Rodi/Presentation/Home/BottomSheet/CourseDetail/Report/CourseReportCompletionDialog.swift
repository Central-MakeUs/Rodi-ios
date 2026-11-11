import SwiftUI

struct CourseReportCompletionDialog: View {
    let confirmAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("신고가 접수되었습니다.")
                            .rodiTypography(.body1SemiBold)
                            .foregroundStyle(RodiColor.black)

                        Text("관리자의 검토 후 빠른 시일내에\n조치 예정입니다.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                    }
                    .frame(minWidth: 240)

                    Button(action: confirmAction) {
                        Text("확인")
                            .rodiTypography(.buttonMedium)
                            .foregroundStyle(RodiColor.white)
                            .frame(width: 116, height: 42)
                            .background(RodiColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                    .accessibilityLabel("신고 완료 확인")
                }
            }
        }
    }
}
