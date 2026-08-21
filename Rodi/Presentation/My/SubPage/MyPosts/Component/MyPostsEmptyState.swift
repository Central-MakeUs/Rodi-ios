import SwiftUI

struct MyPostsEmptyState: View {
    let errorMessage: String?
    let retry: () -> Void
    let openPracticeRecords: () -> Void
    let hasPracticeRecords: Bool

    var body: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                RodiRetryButton(action: retry)
            } else {
                VStack(alignment: .center) {
                    Image("ic_review")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding(.bottom, 16)

                    Text("아직 작성한 후기가 없어요!")
                        .rodiTypography(.headline1)
                        .foregroundStyle(RodiColor.gray600)
                        .padding(.bottom, 8)

                    Text("다녀온 코스의 경험을 기록해보세요.")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)

                    if hasPracticeRecords {
                        Button(action: openPracticeRecords) {
                            Text("연습기록 보러가기")
                                .rodiTypography(.body3Medium)
                                .foregroundStyle(RodiColor.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 7)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(RodiColor.primary, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 16)
                        .accessibilityLabel("연습기록 보러가기")
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 104)
    }
}
