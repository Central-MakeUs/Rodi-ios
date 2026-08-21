import SwiftUI

struct CourseReviewSection: View {
    let summary: PlaceReviewSummary?
    let page: CourseReviewReducer.PageState?
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
            RodiRetryButton(action: onRetry)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
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
