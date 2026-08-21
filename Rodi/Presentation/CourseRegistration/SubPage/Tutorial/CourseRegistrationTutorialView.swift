import SwiftUI

struct CourseRegistrationTutorialView: View {
    let state: CourseRegistrationTutorialReducer.State
    let send: (CourseRegistrationTutorialReducer.Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            CourseRegistrationHeader(
                title: "코스 등록 방법",
                closeAction: { send(.closeTapped) },
                trailingImageName: state.page == 2 ? "ic_check_circle_active" : nil,
                isTrailingEnabled: !state.isCompleting,
                trailingAction: { send(.completionTapped) }
            )
            CourseRegistrationTutorialProgressView(page: state.page)
            CourseRegistrationTutorialPager(
                page: state.page,
                pages: CourseRegistrationTutorialPage.allCases.map { page in
                    AnyView(CourseRegistrationTutorialPageView(page: page))
                },
                pageChanged: { send(.pageChanged($0)) }
            )
        }
        .background(RodiColor.white)
        .rodiSnackbar(message: state.errorMessage)
        .onDisappear { send(.deactivated) }
    }
}

private enum CourseRegistrationTutorialPage: Int, CaseIterable {
    case mapPlacement
    case startSelection
    case pinEditing

    var title: String {
        switch self {
        case .mapPlacement: "지도를 움직여 핀을 놓을 위치를 정하고"
        case .startSelection: "아래 ‘출발지 선택'을 눌러, 위치를 선택해요"
        case .pinEditing: "위치 수정 시 해당 핀을 눌러주세요"
        }
    }

    var description: String {
        switch self {
        case .mapPlacement: "출발지 → 도착지 → 경유지 순서로 코스를 구성해요."
        case .startSelection: "건물이 아닌, 도로 위에 위치 시켜주세요."
        case .pinEditing: "‘핀 수정하기' 화면으로 이동할 수 있어요."
        }
    }
}

private struct CourseRegistrationTutorialPageView: View {
    let page: CourseRegistrationTutorialPage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(page.title)
                        .rodiTypography(.heading2)
                        .foregroundStyle(RodiColor.black)
                    Text(page.description)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(Color(hex: 0xFF966F))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                CourseRegistrationTutorialReferenceImage(page: page)
                    .padding(.bottom, 24)
            }
            .padding(.top, 4)
        }
    }
}

private struct CourseRegistrationTutorialReferenceImage: View {
    let page: CourseRegistrationTutorialPage

    var body: some View {
        GeometryReader { proxy in
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: proxy.size.width * 0.72)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .aspectRatio(CGFloat(552) / (CGFloat(1078) * 0.72), contentMode: .fit)
    }

    private var imageName: String {
        switch page {
        case .mapPlacement: "img_course_tutorial_step_1"
        case .startSelection: "img_course_tutorial_step_2"
        case .pinEditing: "img_course_tutorial_step_3"
        }
    }
}
