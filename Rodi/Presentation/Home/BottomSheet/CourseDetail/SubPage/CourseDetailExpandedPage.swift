import SwiftUI

struct CourseDetailExpandedPage: View {
    @State private var activeReviewDropdown: CourseReviewDropdown?

    let state: CourseDetailBottomSheetReducer.State
    let send: (CourseDetailBottomSheetReducer.Action) -> Void
    let bookmarkAction: () -> Void
    let routeGuidanceAction: () -> Void
    let expandedBackAction: () -> Void

    var body: some View {
        if let detail = state.detail {
            page(detail: detail)
        }
    }
}

private extension CourseDetailExpandedPage {

    @ViewBuilder
    func page(detail: PlaceDetail) -> some View {
        Group {
            if state.reviews.route == .report {
                CourseReviewReportPage(
                    state: state.reviews.report,
                    send: { send(.reviews(.report($0))) }
                )
            } else if state.reviews.route == .allReviews {
                allReviewsPage(detail: detail)
            } else {
                detailPage(detail: detail)
            }
        }
        .overlayPreferenceValue(RodiDropdownAnchorPreferenceKey.self) { anchors in
            CourseReviewDropdownOverlay(
                anchors: anchors,
                state: state.reviews,
                activeDropdown: $activeReviewDropdown,
                send: { send(.reviews($0)) }
            )
        }
        .overlay {
            if state.reviews.block.isConfirmationPresented {
                blockConfirmationDialog
            }
            if state.reviews.deleteTargetReviewID != nil {
                ReviewDeleteConfirmationDialog(
                    isDeleting: state.reviews.isDeleting,
                    errorMessage: state.reviews.deleteErrorMessage,
                    deleteAction: { send(.reviews(.deleteConfirmed)) },
                    cancelAction: { send(.reviews(.deleteCancelled)) }
                )
                .zIndex(20)
            }
        }
    }

    func detailPage(detail: PlaceDetail) -> some View {
        ZStack {
            RodiColor.white
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        courseInformation(detail: detail)
                        routeSection(detail: detail)
                            .padding(.top, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    fullWidthDivider(height: 2)
                        .padding(.vertical, 24)

                    reviewSection
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(dropdownDismissDragGesture)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            fixedHeader(title: nil)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            fixedActionBar(detail: detail)
        }
    }

    func allReviewsPage(detail: PlaceDetail) -> some View {
        CourseDetailAllReviewsPage(
            detail: detail,
            reviewState: state.reviews,
            activeReviewDropdown: $activeReviewDropdown,
            sendReviewAction: { send(.reviews($0)) },
            backAction: { send(.reviews(.backTapped)) },
            dismissDropdownAction: { activeReviewDropdown = nil },
            actionBar: { fixedActionBar(detail: detail) }
        )
    }

    func fullWidthDivider(height: CGFloat) -> some View {
        Rectangle()
            .fill(RodiColor.primaryMinus100)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .accessibilityHidden(true)
    }

    func fixedHeader(title: String?) -> some View {
        Group {
            if let title {
                RodiCenteredNavigationHeader(title: title) {
                    backButton
                } trailing: {
                    Color.clear
                        .accessibilityHidden(true)
                }
            } else {
                headerWithoutTitle
            }
        }
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(RodiColor.white)
    }

    func fixedActionBar(detail: PlaceDetail) -> some View {
        actionBar(detail: detail)
            .background(RodiColor.white)
    }

    var headerWithoutTitle: some View {
        HStack(spacing: 0) {
            backButton
                .frame(width: 44, height: 44)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }

    var backButton: some View {
        Button {
            if state.reviews.route == .allReviews {
                send(.reviews(.backTapped))
            } else if state.presentation == .expandedDetail {
                expandedBackAction()
            } else {
                send(.collapseRequested)
            }
        } label: {
            Image("ic_chevron_left_24")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(state.reviews.route == .allReviews ? "코스 상세로 돌아가기" : "코스 시트로 돌아가기")
    }

    func courseInformation(detail: PlaceDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(detail.name)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)

                bookmarkCountLabel(detail: detail)
            }

            HStack(spacing: 4) {
                if let distance = detail.course?.distanceMeters {
                    Text(formattedDistance(distance))
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.primary)
                }

                Text("주행거리")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray800)
            }

            if !visibleTags(detail).isEmpty || remainingTagCount(detail) > 0 {
                HStack(spacing: 4) {
                    ForEach(visibleTags(detail), id: \.self) { tag in
                        Text(tag)
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.gray600)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RodiColor.gray200)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .lineLimit(1)
                    }

                    if remainingTagCount(detail) > 0 {
                        Text("+\(remainingTagCount(detail))")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.gray700)
                    }
                }
                .lineLimit(1)
            }

            if let cautionText = cautionText(detail) {
                HStack(spacing: 4) {
                    Image("ic_alert_triangle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)

                    Text(cautionText)
                        .rodiTypography(.caption1Medium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundStyle(RodiColor.secondary400)
                .padding(.bottom, 4)
            }

            if let summary = detail.course?.summary, !summary.isEmpty {
                Text(summary)
                    .rodiTypography(.caption1Regular)
                    .foregroundStyle(RodiColor.gray800)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 37)
                    .background(RodiColor.gray100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    func bookmarkCountLabel(detail: PlaceDetail) -> some View {
        HStack(spacing: 2) {
            Image("ic_bookmark_count")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            Text("\(detail.bookmarkCount)")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray700)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("저장 \(detail.bookmarkCount)개")
    }

    func routeSection(detail: PlaceDetail) -> some View {
        let points = RodiCourseItem(placeDetail: detail).routeOverlayPoints
        return VStack(alignment: .leading, spacing: 14) {
            Text("경로 정보")
                .rodiTypography(.headline2)
                .foregroundStyle(RodiColor.black)
                .padding(.bottom, 10)

            if points.isEmpty {
                Text("경로 정보를 준비 중이에요.")
                    .rodiTypography(.caption1Regular)
                    .foregroundStyle(RodiColor.gray600)
            } else {
                CourseRouteTimelineView(points: visibleRoutePoints(points))

                Button {
                    send(.routeTimelineToggled)
                } label: {
                    HStack(spacing: 10) {
                        Text(state.isRouteTimelineExpanded ? "접기" : "자세히 보기")
                            .rodiTypography(.body3Medium)

                        Image("ic_chevron_down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(state.isRouteTimelineExpanded ? 180 : 0))
                    }
                    .foregroundStyle(RodiColor.gray700)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(RodiColor.gray300, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(points.count <= 1)
            }
        }
    }

    var reviewSection: some View {
        CourseReviewView(
            state: state.reviews,
            activeDropdown: $activeReviewDropdown,
            send: { send(.reviews($0)) }
        )
    }

    var dropdownDismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { _ in
                activeReviewDropdown = nil
            }
    }

    func actionBar(detail: PlaceDetail) -> some View {
        HStack(spacing: 8) {
            Button(action: bookmarkAction) {
                Group {
                    if state.isBookmarkUpdating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(detail.isBookmarked ? "ic_bookmark_action_filled" : "ic_bookmark_action")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(width: 46, height: 46)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RodiColor.gray300, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(state.isBookmarkUpdating)
            .accessibilityLabel(detail.isBookmarked ? "북마크 해제" : "북마크 저장")

            Button(action: routeGuidanceAction) {
                HStack(spacing: 8) {
                    if state.isRouteLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(RodiColor.white)
                    }
                    Text("연습하러 가기")
                        .rodiTypography(.buttonMedium)
                }
                .foregroundStyle(RodiColor.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background((detail.course?.waypoints.count ?? 0) >= 2 ? RodiColor.primary : RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled((detail.course?.waypoints.count ?? 0) < 2 || state.isRouteLoading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(RodiColor.white)
        .shadow(color: RodiColor.black.opacity(0.12), radius: 8, x: 0, y: -3)
    }

    var blockConfirmationDialog: some View {
        CourseReviewBlockDialog(
            state: state.reviews.block,
            send: { send(.reviews(.block($0))) }
        )
    }

    func visibleRoutePoints(_ points: [RodiRouteOverlayPoint]) -> [RodiRouteOverlayPoint] {
        state.isRouteTimelineExpanded ? points : Array(points.prefix(1))
    }

    func formattedDistance(_ meters: Int) -> String {
        let kilometers = Double(meters) / 1_000
        return kilometers.rounded() == kilometers
            ? String(format: "%.0fkm", kilometers)
            : String(format: "%.1fkm", kilometers)
    }

    func visibleTags(_ detail: PlaceDetail) -> [String] {
        Array(detail.practiceTypes.map(PlacePracticeType.displayName(for:)).prefix(4))
    }

    func remainingTagCount(_ detail: PlaceDetail) -> Int {
        max(0, detail.practiceTypes.count - visibleTags(detail).count)
    }

    func cautionText(_ detail: PlaceDetail) -> String? {
        let cautions = Array((detail.course?.cautions ?? []).prefix(2))
        return cautions.isEmpty ? nil : cautions.joined(separator: " ･ ")
    }
}
