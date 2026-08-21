import SwiftUI

struct CourseReviewAllContent: View {
    let summary: PlaceReviewSummary?
    let page: CourseReviewReducer.PageState?
    let isSummaryLoading: Bool
    let summaryErrorMessage: String?
    let selectedLevel: ReviewLevelFilter
    let profileLevel: ReviewLevel
    @Binding var activeDropdown: CourseReviewDropdown?
    let onLoadMore: () -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            if let errorMessage = summaryErrorMessage ?? page?.errorMessage {
                retryView(message: errorMessage)
            } else if isSummaryLoading || page?.isInitialLoading == true {
                loadingView
            } else if let summary {
                content(summary: summary)
            } else {
                retryView(message: "후기를 불러오지 못했어요.")
            }
        }
        .zIndex(activeDropdown == nil ? 0 : 1)
    }
}

private extension CourseReviewAllContent {

    func content(summary: PlaceReviewSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            recommendSection(summary: summary)
                .padding(.bottom, 20)

            fullWidthDivider(height: 2)

            difficultySection(summary: summary)
                .padding(.vertical, 24)

            fullWidthDivider(height: 2)

            reviewList
                .padding(.top, 24)
        }
    }

    func recommendSection(summary: PlaceReviewSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("추천해요")
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.gray800)

            HStack(spacing: 4) {
                Image("ic_thumbs_up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)

                Text("\(summary.recommendCount)명")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)
            }
        }
    }

    func difficultySection(summary: PlaceReviewSummary) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("난이도")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)

                Spacer(minLength: 0)

                RodiDropdown(
                    title: displayLevelName(summary: summary),
                    anchorID: CourseReviewDropdown.allReviewsHeader,
                    isExpanded: dropdownBinding
                )
                .accessibilityLabel("후기 레벨 \(displayLevelName(summary: summary))")
            }

            ForEach(ReviewDifficulty.allCases, id: \.self) { difficulty in
                difficultyRow(difficulty, summary: summary)
            }
        }
    }

    func difficultyRow(_ difficulty: ReviewDifficulty, summary: PlaceReviewSummary) -> some View {
        let count = summary.difficultyCounts[difficulty] ?? 0
        let isMostSelected = difficulty == summary.topDifficulty

        return VStack(alignment: .leading, spacing: 4) {
            HStack() {
                Text(difficulty.title)
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(isMostSelected ? RodiColor.primary : RodiColor.gray600)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isMostSelected ? RodiColor.primary100 : RodiColor.gray200)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Spacer()

                Text("\(count)명")
                    .rodiTypography(isMostSelected ? .body1Medium : .body3Medium)
                    .foregroundStyle(isMostSelected ? RodiColor.black : RodiColor.gray600)
            }

            difficultyGauge(
                progress: progress(for: count, summary: summary),
                isMostSelected: isMostSelected
            )
        }
    }

    func difficultyGauge(
        progress: CGFloat,
        isMostSelected: Bool
    ) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(RodiColor.gray300)
                .frame(height: 6)

            Capsule()
                .fill(isMostSelected ? RodiColor.primary400 : RodiColor.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 6)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(Int((progress * 100).rounded()))퍼센트")
    }

    var reviewList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(page?.items ?? []) { review in
                CourseReviewCard(review: review, level: profileLevel) {
                    activeDropdown = .reviewMenu(review.id)
                }
                    .onAppear {
                        guard review.id == page?.items.last?.id,
                              page?.hasNext == true,
                              page?.isLoadingNextPage == false
                        else {
                            return
                        }
                        onLoadMore()
                    }

                if review.id != page?.items.last?.id {
                    fullWidthDivider(height: 2)
                        .padding(.vertical, 24)
                }
            }

            if page?.isLoadingNextPage == true {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .accessibilityLabel("후기를 더 불러오는 중")
            }
        }
    }

    var dropdownBinding: Binding<Bool> {
        Binding(
            get: { activeDropdown == .allReviewsHeader },
            set: { isExpanded in
                activeDropdown = isExpanded ? .allReviewsHeader : nil
            }
        )
    }

    func displayLevelName(summary: PlaceReviewSummary) -> String {
        summary.level?.displayName ?? selectedLevel.displayName
    }

    func progress(for count: Int, summary: PlaceReviewSummary) -> CGFloat {
        let totalCount = max(summary.difficultyCounts.values.reduce(0, +), 1)
        return CGFloat(count) / CGFloat(totalCount)
    }

    func fullWidthDivider(height: CGFloat) -> some View {
        Rectangle()
            .fill(RodiColor.primaryMinus100)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(.horizontal, -16)
            .accessibilityHidden(true)
    }

    var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .accessibilityLabel("후기를 불러오는 중")
    }

    func retryView(message: String) -> some View {
        VStack(spacing: 10) {
            Text(message)
                .rodiTypography(.caption1Regular)
                .foregroundStyle(RodiColor.gray600)

            RodiRetryButton(action: onRetry)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
