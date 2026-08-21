import SwiftUI

struct MyCoursesEmptyState: View {
    let filter: MyPostsReducer.CourseFilter
    let errorMessage: String?
    let retry: () -> Void
    let openCourseRegistration: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                RodiRetryButton(action: retry)
                .padding(.top, 8)
            } else {
                Image("img_my_courses_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 125, height: 50)

                Text(emptyTitle)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray600)
                    .padding(.top, 16)

                if filter == .all {
                    Text("나만 알고 있는 운전 연습하기 좋은\n코스를 공유해보세요.")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    Button(action: openCourseRegistration) {
                        Text("코스 등록하기")
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
                    .contentShape(Rectangle())
                    .padding(.top, 16)
                    .accessibilityLabel("코스 등록하기")
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 104)
    }
}

private extension MyCoursesEmptyState {

    var emptyTitle: String {
        switch filter {
        case .all: "아직 등록한 코스가 없어요!"
        case .approved: "승인된 코스가 없어요!"
        case .pending: "검토중인 코스가 없어요!"
        case .rejected: "반려된 코스가 없어요!"
        }
    }
}
