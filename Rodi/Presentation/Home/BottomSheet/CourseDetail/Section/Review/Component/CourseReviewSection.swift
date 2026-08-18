import SwiftUI

enum CourseReviewDropdown: Hashable {
    case allReviewsHeader
    case summary
    case reviewMenu(Int)
}

struct CourseReviewSection: View {
    let summary: PlaceReviewSummary?
    let page: CourseDetailBottomSheetReducer.ReviewPageState?
    let isSummaryLoading: Bool
    let summaryErrorMessage: String?
    let selectedLevel: ReviewLevelFilter
    let showsAllReviewsButton: Bool
    @Binding var activeDropdown: CourseReviewDropdown?
    let onSelectLevel: (ReviewLevelFilter) -> Void
    let onShowAllReviews: () -> Void
    let onRetry: () -> Void
    let onWriteReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 24)

            if let message = summaryErrorMessage ?? page?.errorMessage {
                retryView(message: message)
            } else if isSummaryLoading || page?.isInitialLoading == true {
                loadingView
            } else {
                detailContent
            }
        }
        .zIndex(activeDropdown == nil ? 0 : 1)
    }
}

private extension CourseReviewSection {

    var header: some View {
        HStack(spacing: 8) {
            Text("레벨별 후기")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            if showsAllReviewsButton {
                Spacer(minLength: 0)
                Button(action: onShowAllReviews) {
                    HStack(spacing: 2) {
                        Text("전체보기")
                            .rodiTypography(.body3Medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(RodiColor.gray400)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("전체 후기 보기")
            }
        }
    }

    var detailContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let review = page?.items.first {
                if let summary, summary.totalReviewCount > 0 {
                    CourseReviewSummaryView(
                        summary: summary,
                        selectedLevel: selectedLevel,
                        isLevelDropdownExpanded: dropdownBinding(for: .summary)
                    )
                    Divider()
                        .overlay(RodiColor.primaryMinus100)
                        .padding(.vertical, 12)
                }
                CourseReviewCard(review: review, level: profileLevel) {
                    activeDropdown = .reviewMenu(review.id)
                }
                fullWidthDivider(height: 1)
                    .padding(.top, 24)
                writeReviewCallToAction
            } else if hasAnyReviews {
                selectedLevelEmptyContent
            } else {
                emptyReviewCallToAction
            }
        }
    }

    var selectedLevelEmptyContent: some View {
        VStack(spacing: 0) {
            if let summary {
                CourseReviewSummaryView(
                    summary: summary,
                    selectedLevel: selectedLevel,
                    isLevelDropdownExpanded: dropdownBinding(for: .summary)
                )
                Divider()
                    .overlay(RodiColor.primaryMinus100)
                    .padding(.vertical, 12)
            }

            emptyReviewCallToAction
        }
    }

    var hasAnyReviews: Bool {
        (summary?.totalReviewCount ?? 0) > 0
    }

    var profileLevel: ReviewLevel {
        switch selectedLevel {
        case .level(let level): level
        case .current: summary?.level ?? .seed
        case .all: .seed
        }
    }

    var emptyReviewCallToAction: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("여러분의 연습 경험을 공유해주세요!")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                Button(action: onWriteReview) {
                    Text("후기 쓰기")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                        .padding(.horizontal, 64)
                        .padding(.vertical, 8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RodiColor.primary, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("후기 쓰기")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)
            .padding(.bottom, 32)

            fullWidthDivider(height: 2)
        }
    }

    var writeReviewCallToAction: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("여러분의 연습 경험을 공유해주세요!")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)

                Button(action: onWriteReview) {
                    Text("후기 쓰기")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                        .padding(.horizontal, 64)
                        .padding(.vertical, 8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RodiColor.primary, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)

            fullWidthDivider(height: 2)
                .padding(.top, 32)
        }
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
            .padding(.vertical, 36)
            .accessibilityLabel("후기를 불러오는 중")
    }

    func retryView(message: String) -> some View {
        VStack(spacing: 10) {
            Text(message)
                .rodiTypography(.caption1Regular)
                .foregroundStyle(RodiColor.gray600)
            Button(action: onRetry) {
                Text("다시 시도")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

struct CourseReviewAllContent: View {
    let summary: PlaceReviewSummary?
    let page: CourseDetailBottomSheetReducer.ReviewPageState?
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

            Button(action: onRetry) {
                Text("다시 시도")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

private extension CourseReviewSection {

    var effectiveSelectedReviewLevel: ReviewLevel? {
        switch selectedLevel {
        case .current:
            summary?.level
        case .level(let level):
            level
        case .all:
            nil
        }
    }

    var reviewLevelDropdown: some View {
        RodiDropdown(
            title: effectiveSelectedReviewLevel?.displayName ?? selectedLevel.displayName,
            anchorID: CourseReviewDropdown.allReviewsHeader,
            isExpanded: dropdownBinding(for: .allReviewsHeader)
        )
        .accessibilityLabel("후기 레벨")
    }

    func dropdownBinding(for dropdown: CourseReviewDropdown) -> Binding<Bool> {
        Binding(
            get: { activeDropdown == dropdown },
            set: { isExpanded in
                activeDropdown = isExpanded ? dropdown : nil
            }
        )
    }
}

struct CourseReviewSummaryView: View {
    let summary: PlaceReviewSummary
    let selectedLevel: ReviewLevelFilter
    @Binding var isLevelDropdownExpanded: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            recommendSummary
                .padding(.leading, 32)
            Rectangle()
                .fill(RodiColor.gray300)
                .frame(width: 1, height: 48)
            difficultySummary
        }
    }

    private var recommendSummary: some View {
        VStack(spacing: 4) {
            Text("추천해요")
                .font(.pretendard(size: 15, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(RodiColor.gray800)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image("ic_thumbs_up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text("\(summary.recommendCount)명")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
    }

    private var difficultySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("난이도")
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(RodiColor.gray800)

                Spacer(minLength: 0)

                levelPicker
            }

            HStack(spacing: 8) {
                if let difficulty = summary.topDifficulty {
                    Text(difficulty.title)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray600)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RodiColor.gray200)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                Text("\(summary.topDifficultyCount)명")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var levelPicker: some View {
        RodiDropdown(
            title: displayLevelName,
            anchorID: CourseReviewDropdown.summary,
            isExpanded: $isLevelDropdownExpanded
        )
        .accessibilityLabel("후기 레벨 \(displayLevelName)")
    }

    private var displayLevelName: String {
        summary.level?.displayName ?? selectedLevel.displayName
    }

}

struct CourseReviewCard: View {
    let review: PlaceReviewItem
    let level: ReviewLevel
    let onMoreTapped: (() -> Void)?

    init(
        review: PlaceReviewItem,
        level: ReviewLevel,
        onMoreTapped: (() -> Void)? = nil
    ) {
        self.review = review
        self.level = level
        self.onMoreTapped = onMoreTapped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RodiLevelProfileImage(
                    level: level,
                    size: 30,
                    backgroundColor: RodiColor.primary100,
                    cornerRadius: 15,
                    imageOffsetY: 0
                )

                Text(review.displayNickname)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)

                Spacer(minLength: 0)

                Button {
                    onMoreTapped?()
                } label: {
                    Image("ic_more_horizontal")
                        .frame(width: 18, height: 30, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .disabled(onMoreTapped == nil)
                .accessibilityLabel("후기 메뉴")
                .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
                    [AnyHashable(CourseReviewDropdown.reviewMenu(review.id)): $0]
                }
            }

            HStack(spacing: 4) {
                if review.isVerifiedVisit {
                    CourseReviewBadge(title: "방문인증", style: .verified)
                }
                CourseReviewBadge(title: review.practiceMethodDisplayName, style: .practiceMethod)
            }

            VStack(alignment: .trailing, spacing: 6) {
                if !review.content.isEmpty {
                    Text(review.content)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray800)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 0) {
                    Spacer(minLength: 0)

                    Text(review.createdAt.reviewDisplayDate)
                        .rodiTypography(.caption2Medium)
                        .foregroundStyle(RodiColor.gray500)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct CourseReviewBadge: View {
    enum Style {
        case verified
        case practiceMethod
    }

    let title: String
    let style: Style

    var body: some View {
        Text(title)
            .rodiTypography(.caption2Medium)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(borderColor, lineWidth: 1)
            }
    }

    private var foregroundColor: Color {
        switch style {
        case .verified: RodiColor.primary
        case .practiceMethod: RodiColor.gray600
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .verified: RodiColor.primary100
        case .practiceMethod: RodiColor.gray50
        }
    }

    private var borderColor: Color {
        switch style {
        case .verified: RodiColor.primary200
        case .practiceMethod: RodiColor.gray200
        }
    }
}

private extension String {
    var reviewDisplayDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: self)
            ?? ISO8601DateFormatter().date(from: self)
            ?? dateWithoutTimeZone
        guard let date else { return self }
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ko_KR_POSIX")
        displayFormatter.dateFormat = "yy.MM.dd"
        return displayFormatter.string(from: date)
    }

    private var dateWithoutTimeZone: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: self) {
                return date
            }
        }
        return nil
    }
}
