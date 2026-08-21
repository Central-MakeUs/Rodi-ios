import SwiftUI

/// 후기 영역에서 발생한 anchor preference를 소비해 레벨·카드 메뉴를 최상단에 표시한다.
/// anchor를 만드는 카드와 메뉴 행동을 같은 Feature에 두어 CourseDetail page가 후기 상태를 해석하지 않게 한다.
struct CourseReviewDropdownOverlay: View {
    let anchors: [AnyHashable: Anchor<CGRect>]
    let state: CourseReviewReducer.State
    @Binding var activeDropdown: CourseReviewDropdown?
    let send: (CourseReviewReducer.Action) -> Void

    var body: some View {
        if let activeDropdown,
           let anchor = anchors[activeDropdown] {
            GeometryReader { proxy in
                let triggerFrame = proxy[anchor]

                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.activeDropdown = nil
                        }

                    dropdownMenu(
                        for: activeDropdown,
                        triggerFrame: triggerFrame
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
            .zIndex(10)
        }
    }
}

private extension CourseReviewDropdownOverlay {
    var selectedLevel: ReviewLevel? {
        switch state.selectedLevel {
        case .current:
            summaryState.value?.level
        case .level(let level):
            level
        case .all:
            nil
        }
    }

    var summaryState: CourseReviewReducer.SummaryState {
        state.summaries[state.selectedLevel] ?? .init()
    }

    var reviewLevelOptions: [RodiDropdownOption] {
        ReviewLevel.allCases
            .filter { $0 != selectedLevel }
            .map { .init(id: $0.rawValue, title: $0.displayName) }
    }

    func reviewActionOptions(for reviewID: Int) -> [RodiDropdownOption] {
        let isMine = state.pages.values
            .lazy
            .flatMap(\.items)
            .first(where: { $0.id == reviewID })?
            .isMine == true

        return isMine
            ? [
                .init(id: "edit", title: "수정하기"),
                .init(id: "delete", title: "삭제하기")
            ]
            : [
                .init(id: "report", title: "신고하기"),
                .init(id: "block", title: "차단")
            ]
    }

    @ViewBuilder
    func dropdownMenu(
        for dropdown: CourseReviewDropdown,
        triggerFrame: CGRect
    ) -> some View {
        switch dropdown {
        case .allReviewsHeader, .summary:
            RodiDropdownMenu(
                options: reviewLevelOptions,
                onSelect: { option in
                    activeDropdown = nil
                    guard let level = ReviewLevel(rawValue: option.id) else { return }
                    send(.levelSelected(.level(level)))
                }
            )
            .alignmentGuide(.leading) { dimensions in
                dimensions[.trailing] - triggerFrame.maxX
            }
            .alignmentGuide(.top) { dimensions in
                dimensions[.top] - triggerFrame.maxY - 8
            }

        case .reviewMenu(let reviewID):
            RodiDropdownMenu(
                options: reviewActionOptions(for: reviewID),
                onSelect: { option in
                    activeDropdown = nil
                    switch option.id {
                    case "edit":
                        send(.editRequested(reviewID: reviewID))
                    case "delete":
                        send(.deleteRequested(reviewID: reviewID))
                    case "report":
                        send(.reportRequested(reviewID: reviewID))
                    case "block":
                        send(.blockRequested(reviewID: reviewID))
                    default:
                        break
                    }
                }
            )
            .alignmentGuide(.leading) { dimensions in
                dimensions[.trailing] - triggerFrame.maxX
            }
            .alignmentGuide(.top) { dimensions in
                dimensions[.top] - triggerFrame.maxY - 4
            }
        }
    }
}
