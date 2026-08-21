import SwiftUI

struct CourseDetailAllReviewsPage<ActionBar: View>: View {
    let detail: PlaceDetail
    let reviewState: CourseReviewReducer.State
    @Binding var activeReviewDropdown: CourseReviewDropdown?
    let sendReviewAction: (CourseReviewReducer.Action) -> Void
    let backAction: () -> Void
    let dismissDropdownAction: () -> Void
    let actionBar: () -> ActionBar

    var body: some View {
        ZStack {
            RodiColor.white
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CourseReviewView(
                        state: reviewState,
                        activeDropdown: $activeReviewDropdown,
                        send: sendReviewAction
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(dropdownDismissDragGesture)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RodiCenteredNavigationHeader(title: "레벨별 후기") {
                Button(action: backAction) {
                    Image("ic_chevron_left_24")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("코스 상세로 돌아가기")
            } trailing: {
                Color.clear
                    .accessibilityHidden(true)
            }
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(RodiColor.white)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar()
        }
    }
}

private extension CourseDetailAllReviewsPage {

    var dropdownDismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { _ in
                dismissDropdownAction()
            }
    }
}
